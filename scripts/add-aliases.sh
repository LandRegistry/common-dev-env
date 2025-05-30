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
alias psql17="$DC_CMD exec postgres-17 psql -h postgres-17 -U root -d"
alias db2co="$DC_CMD exec --user db2inst1 db2_community bash -c '~/sqllib/bin/db2'"
alias gitlist="bash $DEV_ENV_ROOT_DIR/scripts/git_list.sh"
alias gitpull="bash $DEV_ENV_ROOT_DIR/scripts/git_pull.sh"
alias cadence-cli="docker run --rm ubercadence/cli:0.7.0 --address host.docker.internal:7933"

function bashin(){
  app_name=${@:1}
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
    echo "On a Windows Machine"
    winpty docker exec -it $app_name bash
  else
    docker exec -it $app_name bash
  fi
}

function unit-test(){
    reportflag=off
    app_name=${1}

    # Check if there's a -r argument (the only one supported) and set a flag if so
    shift
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
    ex ${1} make integrationtest
}

function lint(){
    reportflag=off
    fixflag=off
    app_name=${1}

    # Check if there's a -r or -f argument (the only ones supported) and set a flag if so
    shift
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
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
    winpty docker exec -it ${1} make format
  else
    ex ${1} make format
  fi
    
}

function acceptance-test(){
    run ${1} sh run_tests.sh ${@:2}
}
function acctest(){
    run ${1} sh run_tests.sh ${@:2}
}

function acceptance-lint(){
    run ${1} sh run_linting.sh
}

function acclint(){
    run ${1} sh run_linting.sh
}

function manage(){
    ex ${1} python3 manage.py ${@:2}
}

function localstack(){
    ex localstack awslocal ${@:1}
}

function fullreset(){
    stop ${1}
    remove ${1}
    ruby $DEV_ENV_ROOT_DIR/scripts/commodities_standalone.rb ${1}
    rebuild ${1}
}

function alembic(){
    ex -e SQL_USE_ALEMBIC_USER=yes -e SQL_PASSWORD=superroot -e SQLALCHEMY_POOL_RECYCLE=3600 ${1} \
        bash -c 'cd /src && python3 manage.py db '"${@:2}"''
}

function devenv-help(){
  cat <<EOF
    If typing a docker-compose command you can use the alias dc instead. For example "dc ps" rather than "docker-compose ps".

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
    fullreset <name of container>                    -     Performs stop, remove then rebuild. Useful if a container (like a database) needs to be wiped. Remember to reset .commodities if you do though to ensure init fragments get rerun
    bashin <name of container>                       -     bash in to a container
    unit-test <name of container> [-r]               -     run the unit tests for an application (this expects there to be a Makefile with a unittest command).
                                                           if you add -r it will output reports to the test-output folder.
    integration-test <name of container>             -     run the integration tests for an application (this expects there to be a Makefile with a integrationtest command)
    acceptance-test | acctest                        -     run the acceptance tests run_tests.sh script inside the given container. If using the skeleton, any further parameters will be passed to cucumber.
                <name of container> <cucumber args>
    acceptance-lint | acclint                        -     run the acceptance tests run_linting.sh script inside the given container.
                <name of container>
    format <name of container>                       -     run the formatter for an application (this expects there to be a Makefile with a format command)
    lint <name of container> [-r] [-f]               -     run the linter for an application (this expects there to be a Makefile with a lint command)
                                                           if you add -r it will output reports to the test-output folder
                                                           if you add -f it will automatically fix issues where possible
                                                           (flags can be combined)
    psql13 <name of database>                        -     run psql in the postgres-13 container
    psql17 <name of database>                        -     run psql in the postgres-17 container
    db2co                                            -     run db2 command line in the db2_community container
    manage <name of container> <command>             -     run manage.py commands in a container
    alembic <name of container> <command>            -     run an alembic db command in a container, with the appropriate environment variables preset
    add-to-docker-compose
      <name of new compose fragment>                 -     looks in fragments folder of loaded apps to search for a new compose-fragment including the provided parameter eg docker-compose-syt2-fragment then runs docker-compose up
    cadence-cli                                      -     runs the command line tool to interact with cadence orchestrator
    localstack                                       -     run localstack (aws) commands in the localstack container
EOF
}
