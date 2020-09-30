#!/usr/bin/env bash

# Save the dev-env root directory for use in aliases and functions
export DEV_ENV_ROOT_DIR=$(pwd)

# Aliases for common commands
alias dc="docker-compose --compatibility"
alias stop="docker-compose --compatibility stop"
alias start="docker-compose --compatibility start"
alias restart="docker-compose --compatibility restart"
alias rebuild="docker-compose --compatibility up --build -d"
alias remove="docker-compose --compatibility rm -v -f"
alias logs="docker-compose --compatibility logs"
alias livelogs="docker attach --no-stdin --sig-proxy=false"
alias ex="docker-compose --compatibility exec"
alias status="docker-compose --compatibility ps"
alias run="docker-compose --compatibility run --rm"
alias psql="docker-compose --compatibility exec postgres psql -h postgres -U root -d"
alias db2="docker-compose --compatibility exec --user db2inst1 db2 bash -c '~/sqllib/bin/db2'"
alias psql96="docker-compose --compatibility exec postgres-96 psql -h postgres-96 -U root -d"
alias db2c="docker-compose --compatibility exec --user db2inst1 db2_devc bash -c '~/sqllib/bin/db2'"
alias db2co="docker-compose --compatibility exec --user db2inst1 db2_community bash -c '~/sqllib/bin/db2'"
alias gitlist="bash $DEV_ENV_ROOT_DIR/scripts/git_list.sh"
alias gitpull="bash $DEV_ENV_ROOT_DIR/scripts/git_pull.sh"
alias cadence-cli="docker run --rm ubercadence/cli:0.7.0 --address host.docker.internal:7933"

function bashin(){
    docker exec -it ${@:1} bash
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
       docker-compose --compatibility exec $app_name make report="true" unittest
    else
       docker-compose --compatibility exec $app_name make unittest
    fi

    # docker network connect dv_default $app_name
}

function integration-test(){
    docker-compose --compatibility exec ${1} make integrationtest
}

function acceptance-test(){
    docker-compose --compatibility run --rm ${1} sh run_tests.sh ${@:2}
}
function acctest(){
    docker-compose --compatibility run --rm ${1} sh run_tests.sh ${@:2}
}

function acceptance-lint(){
    docker-compose --compatibility run --rm ${1} sh run_linting.sh
}

function acclint(){
    docker-compose --compatibility run --rm ${1} sh run_linting.sh
}

function manage(){
    docker-compose --compatibility exec ${1} python3 manage.py ${@:2}
}

function fullreset(){
    docker-compose --compatibility stop ${1}
    docker-compose --compatibility rm -v -f ${1}
    ruby $DEV_ENV_ROOT_DIR/scripts/commodities_standalone.rb ${1}
    docker-compose --compatibility up --build -d ${1}
}

function alembic(){
    docker-compose --compatibility exec ${1} bash -c 'cd /src && export SQL_USE_ALEMBIC_USER=yes && export SQL_PASSWORD=superroot && python3 manage.py db '"${@:2}"''
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
  docker-compose --compatibility up -d
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
    exec <name of container> <command to execute>    -     execute a command in a running container
    run <options> <name of container> <command>      -     creates a new container and runs the command in it
    remove <name of container>                       -     remove a container
    rebuild <name of container>                      -     checks if a container needs rebuilding and rebuilds/recreates/restarts it if so, otherwise does nothing. Useful if you've just changed a file that the Dockerfile copies into the image.
    fullreset <name of container>                    -     Performs stop, remove then rebuild. Useful if a container (like a database) needs to be wiped. Remember to reset .commodities if you do though to ensure init fragments get rerun
    bashin <name of container>                       -     bash in to a container
    unit-test <name of container> [-r]               -     run the unit tests for an application (this expects there to a be a Makefile with a unittest command).
                                                           if you add -r it will output reports to the test-output folder.
    integration-test <name of container>             -     run the integration tests for an application (this expects there to a be a Makefile with a integrationtest command)
    acceptance-test | acctest                        -     run the acceptance tests run_tests.sh script inside the given container. If using the skeleton, any further parameters will be passed to cucumber.
                <name of container> <cucumber args>
    acceptance-lint | acclint                        -     run the acceptance tests run_linting.sh script inside the given container.
                <name of container>
    psql[96] <name of database>                      -     run psql in the postgres/postgres-96 container
    db2[c][co]                                        -     run db2 command line in the db2/db2_devc/db2_community container
    manage <name of container> <command>             -     run manage.py commands in a container
    alembic <name of container> <command>            -     run an alembic db command in a container, with the appropriate environment variables preset
    add-to-docker-compose
      <name of new compose fragment>                 -     looks in fragments folder of loaded apps to search for a new docker-compose-fragment including the provided parameter eg docker-compose-syt2-fragment then runs docker-compose up
EOF
}
