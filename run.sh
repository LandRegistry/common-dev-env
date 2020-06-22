command="$1"
if [ "$command" = "up" ]
then
    echo -e "\e[36mBeginning UP\e[0m"
    ruby logic.rb --check-for-update --prepare-config --update-apps --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --build-images --provision-commodities --start-apps &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "quickup" ]
then
    echo -e "\e[36mBeginning UP (Quick mode)\e[0m"
    ruby logic.rb --check-for-update --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --start-apps &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "halt" ]
then
    echo -e "\e[36mBeginning HALT\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps &&
    source scripts/docker_clean.sh &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh
fi

if [ "$command" = "reload" ]
then
    echo -e "\e[36mBeginning RELOAD\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps --prepare-config --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --build-images --provision-commodities --start-apps &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "quickreload" ]
then
    echo -e "\e[36mBeginning RELOAD (Quick mode)\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --stop-apps --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --start-apps &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "destroy" ]
then
    echo -e "\e[36mBeginning DESTROY\e[0m"
    ruby logic.rb --prepare-compose &&
    source scripts/docker_prepare.sh &&
    ruby logic.rb --reset &&
    export COMPOSE_FILE= &&
    export COMPOSE_PROJECT_NAME= &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh
fi

if [ "$command" = "repair" ]
then
    echo -e "\e[36mBeginning REPAIR\e[0m"
    ruby logic.rb prepare-compose &&
    source scripts/docker_prepare.sh &&
    source scripts/add-aliases.sh
fi
