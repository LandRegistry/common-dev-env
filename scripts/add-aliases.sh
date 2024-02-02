#!/usr/bin/env bash

# Save the dev-env root directory for use in aliases and functions
export DEV_ENV_ROOT_DIR=$(pwd)

# Aliases for common commands
alias dc="$DC_CMD"
alias stop="$DC_CMD stop"
alias start="$DC_CMD start"
alias restart="$DC_CMD restart"
alias rebuild="$DC_CMD up --build -d"
alias remove="$DC_CMD rm -v -f"
alias logs="$DC_CMD logs"
alias livelogs="docker attach --no-stdin --sig-proxy=false"
alias ex="$DC_CMD exec"
alias status="$DC_CMD ps"
alias run="$DC_CMD run --rm"
alias psql13="$DC_CMD exec postgres-13 psql -h postgres-13 -U root -d"
alias db2co="$DC_CMD exec --user db2inst1 db2_community bash -c '~/sqllib/bin/db2'"
alias gitlist="bash $DEV_ENV_ROOT_DIR/scripts/git_list.sh"
alias gitpull="bash $DEV_ENV_ROOT_DIR/scripts/git_pull.sh"
alias cadence-cli="docker run --rm ubercadence/cli:0.7.0 --address host.docker.internal:7933"

# ------ START: Convenience functions for helping auto-detect the docker service from the current directory -----
if [ -n "$BASH" ]; then
  _whatshell="bash"
elif [ -n "$ZSH_VERSION" ]; then
  _whatshell="zsh"
fi

function _locate_nearest_compose_fragment_file() {
  _curdir=$(pwd)
  # Load all of the different docker compose fragment filenames into an array
  if [[ "${_whatshell}" == "bash" ]]; then
    IFS=':' read -ra _composefiles_arr <<< "$COMPOSE_FILE"
  else
    IFS=':' read -rA _composefiles_arr <<< "$COMPOSE_FILE"
  fi

  # For each dirname, from the current dirname up to the root directory
  while [ ${_curdir} != '/' ]; do
    declare -a _matches

    # Check each compose file to see if it shares a prefix with the current dirname we're looking at
    for composefile in "${_composefiles_arr[@]}"; do
      if [[ "${composefile#"$_curdir"}" != "${composefile}" ]]; then
        _matches+=("${composefile}")
      fi
    done

    # If we've got multiple compose fragments that match, bail, don't want to try to work out which to use
    if [[ "${#_matches[@]}" -gt 1 ]]; then
      return
    # If only one of the compose fragments shares a directory prefix, we've got a clear match
    elif [[ "${#_matches[@]}" -eq 1 ]]; then
      # Return the first (only) match; syntax is cross-compatible with zsh. Direct indexing fails (bash is 0-indexed, zsh is 1-indexed)
      echo "${_matches[@]:0:1}"
      return 0
    fi

    # If no matches at this level, strip the basename and try the dir above
    _curdir=$(dirname ${_curdir})
  done
}

function _find_service_name_in_compose_fragment() {
  # Try to find the name of the docker container associated with this repository.
  _fragmentfile=$(_locate_nearest_compose_fragment_file)

  if [[ "${_fragmentfile}" == "" ]]; then
    return
  fi

  # If the compose fragment declares multiple services, let's default to the first one.
  # If this is wrong the user will need to declare the service explicitly.
  # common-dev-env requires ruby so let's use that to do the string manip more easily
  ruby <<EOF
require 'yaml'
fragment = YAML.load_file("${_fragmentfile}")
STDERR.puts "\e[0;33mwarning\e[0;37m: multiple docker services in fragment; defauting to the first entry" if fragment['services'].size != 1
STDERR.puts "Found docker service: #{fragment['services'].keys[0]}"
puts fragment['services'].values[0]['container_name']
EOF
}

# Cache the known docker compose services, as the command takes a bit of time to run - want to avoid doing every time.
# Eval required here for compatability with zsh
export DEV_ENV_SEARCHABLE_SERVICE_LIST=":$(eval $DC_CMD config --services|tr '\n' ':')"
function _get_app_name_from_first_arg_else_nearest_compose_fragment() {
  # Check the first argument passed;
  # if it matches a docker compose service we know about, use it
  # else search for a docker compose fragment and use the first service from that
  app_name=${1}
  if ! echo "${DEV_ENV_SEARCHABLE_SERVICE_LIST}" | grep ":${app_name}:" &> /dev/null; then
    app_name=$(_find_service_name_in_compose_fragment)
  fi
  echo ${app_name}
}
# ------ END: Convenience functions for helping auto-detect the docker service from the current directory -----

function bashin(){
  app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
    echo "On a Windows Machine"
    winpty docker exec -it ${app_name} bash
  else
    docker exec -it ${app_name} bash
  fi
}

function unit-test(){
    reportflag=off
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi

    # Check if there's a -r argument (the only one supported) and set a flag if so
    while [ $# -gt 0 ]
    do
      case "$1" in
        -r)  reportflag=on;;
        *)
            echo >&2 "usage: unit-test <container_name> [-r]"
          return;;
      esac
      shift
    done

    # Would like to disconnect network during unit tests but Gradle needs it for test library downloads
    # docker network disconnect dv_default $app_name

    # If the report flag is set generate report output otherwise just run the tests
    if [ "$reportflag" = on ] ; then
      ex $app_name make report="true" unittest
    else
      ex $app_name make unittest
    fi

    # docker network connect dv_default $app_name
}

function integration-test(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    ex ${app_name} make integrationtest
}

function lint(){
    reportflag=off
    fixflag=off
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi

    # Check if there's a -r or -f argument (the only ones supported) and set a flag if so
    while [ $# -gt 0 ]
    do
      case "$1" in
        -r) 
          reportflag=on;;
        -f)
          fixflag=on;;
        *)
          echo >&2 "Invalid option used"
          echo >&2 "usage: lint <container_name> [-r] [-f]"
          return;;
      esac
      shift
    done

    if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
      windows=true
    else
      windows=false
    fi

    # If the report/fix flag is set generate report output / fix issues otherwise just run the linter
    if [ "$reportflag" = on ] ; then
      if [ "$fixflag" = on ] ; then
        if [ "$windows" = true ] ; then
          winpty docker exec -it $app_name make report="true" fix="true" lint
        else
          ex $app_name make report="true" fix="true" lint
        fi
      else
        if [ "$windows" = true ] ; then
          winpty docker exec -it $app_name make report="true" lint
        else
          ex $app_name make report="true" lint
        fi
      fi
    elif [ "$fixflag" = on ] ; then
      if [ "$windows" = true ] ; then
        winpty docker exec -it $app_name make fix="true" lint
      else
        ex $app_name make fix="true" lint
      fi
    else
      if [ "$windows" = true ] ; then
        winpty docker exec -it $app_name make lint
      else
        ex $app_name make lint
      fi
    fi
}

function format(){
  app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
  if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
    winpty docker exec -it ${app_name} make format
  else
    ex ${app_name} make format
  fi
    
}

function acceptance-test(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    run ${app_name} sh run_tests.sh ${@:1}
}
function acctest(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    run ${app_name} sh run_tests.sh ${@:1}
}

function acceptance-lint(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    run ${app_name} sh run_linting.sh
}

function acclint(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    run ${app_name} sh run_linting.sh
}

function manage(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    ex ${app_name} python3 manage.py ${@:1}
}

function localstack(){
    ex localstack awslocal ${@:1}
}

function fullreset(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    stop ${app_name}
    remove ${app_name}
    ruby $DEV_ENV_ROOT_DIR/scripts/commodities_standalone.rb ${app_name} $DC_VERSION
    rebuild ${app_name}
}

function alembic(){
    app_name=$(_get_app_name_from_first_arg_else_nearest_compose_fragment ${1})
    if [[ -n "${1}" && "${app_name}" == "${1}" ]]; then shift; fi
    ex -e SQL_USE_ALEMBIC_USER=yes -e SQL_PASSWORD=superroot -e SQLALCHEMY_POOL_RECYCLE=3600 ${app_name} \
        bash -c 'cd /src && python3 manage.py db '"${@:1}"''
}

function add-to-docker-compose(){
  COMPOSE_FILE_LIST=$(printenv COMPOSE_FILE)
  IFS=':' read -r -a array <<< "$COMPOSE_FILE_LIST"
  for element in "${array[@]}"
    do
      if [ -f ${element%/*}/docker-compose-${1}-fragment.yml ]; then
        COMPOSE_FILE_LIST="$COMPOSE_FILE_LIST:${element%/*}/docker-compose-${1}-fragment.yml"
      fi
    done
  export COMPOSE_FILE=$COMPOSE_FILE_LIST
  alias test="$DC_CMD up -d"
  test
}

function devenv-help(){
  echo -e "  \e[0;33mIf typing a docker-compose command you can use the alias dc instead. For example \"dc ps\" rather than \"docker-compose ps\".\e[0;37m

  \e[0;33mCommands:\e[0;37m
    gitlist                                          -     lists all apps and the current branch. Uses the contents of apps/ and not the list in configuration.yml
    gitpull                                          -     Does a git pull for every repository found in /apps, regardless of configuration.yml settings
    status                                           -     view the status of all running containers
    stop <name of container>                         -     stop a container
    start <name of container>                        -     start a container
    restart <name of container>                      -     restart a container
    logs <name of container>                         -     view the logs of a container (from the past)
    livelogs <name of container>                     -     view the logs of a container (as they happen)
    ex <name of container> <command to execute>      -     execute a command in a running container
    run <options> <name of container> <command>      -     creates a new container and runs the command in it
    remove <name of container>                       -     remove a container
    rebuild <name of container>                      -     checks if a container needs rebuilding and rebuilds/recreates/restarts it if so, otherwise does nothing. Useful if you've just changed a file that the Dockerfile copies into the image.
   \e[0;33m*\e[0;37mfullreset [<name of container>]                  -     Performs stop, remove then rebuild. Useful if a container (like a database) needs to be wiped. Remember to reset .commodities if you do though to ensure init fragments get rerun
   \e[0;33m*\e[0;37mbashin [<name of container>]                     -     bash in to a container
   \e[0;33m*\e[0;37munit-test [<name of container>] [-r]             -     run the unit tests for an application (this expects there to be a Makefile with a unittest command).
                                                           if you add -r it will output reports to the test-output folder.
   \e[0;33m*\e[0;37mintegration-test [<name of container>]           -     run the integration tests for an application (this expects there to be a Makefile with a integrationtest command)
   \e[0;33m*\e[0;37macceptance-test | acctest                        -     run the acceptance tests run_tests.sh script inside the given container. If using the skeleton, any further parameters will be passed to cucumber.
                <name of container> <cucumber args>
   \e[0;33m*\e[0;37macceptance-lint | acclint                        -     run the acceptance tests run_linting.sh script inside the given container.
                <name of container>
   \e[0;33m*\e[0;37mformat [<name of container>]                     -     run the formatter for an application (this expects there to be a Makefile with a format command)
   \e[0;33m*\e[0;37mlint [<name of container>] [-r] [-f]             -     run the linter for an application (this expects there to be a Makefile with a lint command)
                                                           if you add -r it will output reports to the test-output folder
                                                           if you add -f it will automatically fix issues where possible
                                                           (flags can be combined)
    psql13 <name of database>                        -     run psql in the postgres-13 container
    db2co                                            -     run db2 command line in the db2_community container
   \e[0;33m*\e[0;37mmanage [<name of container>] <command>           -     run manage.py commands in a container
   \e[0;33m*\e[0;37malembic [<name of container>] <command>          -     run an alembic db command in a container, with the appropriate environment variables preset
    add-to-docker-compose
      <name of new compose fragment>                 -     looks in fragments folder of loaded apps to search for a new docker-compose-fragment including the provided parameter eg docker-compose-syt2-fragment then runs docker-compose up
    cadence-cli                                      -     runs the command line tool to interact with cadence orchestrator
    localstack                                       -     run localstack (aws) commands in the localstack container

  \e[0;33m* Commands marked with an asterisk don't require the container name to be provided explicitly. If omitted, it will find the service associated with your current working directory (or parent directories) and use that.\e[0;37m"
}
