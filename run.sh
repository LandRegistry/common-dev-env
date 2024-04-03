export DC_VERSION=1

# No docker-compose command means v2 is implied
docker-compose > /dev/null 2>&1
retVal=$?
if [ $retVal -ne 0 ]; then
  DC_VERSION=2
else
  docker-compose version 2>&1 | grep -q 'version 2\|version v2' && DC_VERSION=2
fi

if [ "$DC_VERSION" = "2" ] ; then
  echo -e "\e[35mUsing Docker-Compose version 2 commands\e[0m"
  export DC_CMD='docker compose'
else
  export DC_CMD='docker-compose --compatibility'
fi

# Best effort check that the script has been sourced.
# From https://stackoverflow.com/a/28776166
sourced=0
if [ -n "$ZSH_EVAL_CONTEXT" ]; then
  case $ZSH_EVAL_CONTEXT in *:file) sourced=1;; esac
elif [ -n "$KSH_VERSION" ]; then
  [ "$(cd $(dirname -- $0) && pwd -P)/$(basename -- $0)" != "$(cd $(dirname -- ${.sh.file}) && pwd -P)/$(basename -- ${.sh.file})" ] && sourced=1
elif [ -n "$BASH_VERSION" ]; then
  (return 0 2>/dev/null) && sourced=1
else # All other shells: examine $0 for known shell binary filenames
  # Detects `sh` and `dash`; add additional shell filenames as needed.
  case ${0##*/} in sh|dash) sourced=1;; esac
fi

if test $sourced -eq 0; then
    echo -e "\e[36mIt looks like you have executed the script directly instead of sourcing it. This will cause problems due to unset environment variables afterwards. I'll give you 10 seconds to CTRL-C out before continuing...\e[0m"
    sleep 10
fi

command="$1"
subcommands="$2"
if [ "$command" = "up" ]
then
    echo -e "\e[36mBeginning UP\e[0m"
    ruby logic.rb --check-for-update --prepare-config --update-apps --prepare-compose "${subcommands}" &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh &&
    ruby logic.rb --build-images --provision-commodities --start-apps "${subcommands}"

elif [ "$command" = "quickup" ]
then
    echo -e "\e[36mBeginning UP (Quick mode)\e[0m"
    ruby logic.rb --check-for-update --prepare-compose &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh &&
    ruby logic.rb --start-apps

elif [ "$command" = "halt" ]
then
    echo -e "\e[36mBeginning HALT\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps &&
    source scripts/docker_clean.sh &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh

elif [ "$command" = "reload" ]
then
    echo -e "\e[36mBeginning RELOAD\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps --prepare-config --update-apps --prepare-compose "${subcommands}" &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh &&
    ruby logic.rb --build-images --provision-commodities --start-apps "${subcommands}"

elif [ "$command" = "quickreload" ]
then
    echo -e "\e[36mBeginning RELOAD (Quick mode)\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps --prepare-compose &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh &&
    ruby logic.rb --start-apps

elif [ "$command" = "destroy" ]
then
    echo -e "\e[36mBeginning DESTROY\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --reset &&
    export COMPOSE_FILE= &&
    export COMPOSE_PROJECT_NAME= &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh

elif [ "$command" = "repair" ]
then
    echo -e "\e[36mBeginning REPAIR\e[0m"
    ruby logic.rb prepare-compose &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh

else
    echo "Syntax:
   source run.sh [command] [flags]

   commands:
      up            configure, build and run all services; will pull updates
                    from services' git repos and rebuild images
      quickup       as per up, but without updating services' git repos or
                    rebuilding images
      halt          stop all containers
      reload        stop all containers, rebuild them, and restart them
                    (including commodity fragments)
      quickreload   as per reload, but without rebuilding images 
      destroy       stop and remove all containers, then remove all built
                    images and (optionally) reset common-dev-env configuration
      repair        set the docker-compose configuration to use *this* dev-env,
                    for users with several common-dev-env instances

   flags:
      -n, --nopull  for 'up' and 'reload' only; avoid docker hub ratelimiting 
                    by not checking for updates to FROM images used in 
                    Dockerfiles"
fi
