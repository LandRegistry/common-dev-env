command="$1"
if [ "$command" = "up" ]
then
    echo -e "\e[36mBeginning UP\e[0m"
    ruby logic.rb check-for-update &&
    ruby logic.rb prep &&
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    ruby logic.rb start &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "halt" ]
then
    echo -e "\e[36mBeginning HALT\e[0m"
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    ruby logic.rb stop &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh
fi

if [ "$command" = "reload" ]
then
    echo -e "\e[36mBeginning RELOAD\e[0m"
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    ruby logic.rb stop &&

    ruby logic.rb prep &&
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    ruby logic.rb start &&
    source scripts/after-ups.sh &&
    source scripts/add-aliases.sh
fi

if [ "$command" = "destroy" ]
then
    echo -e "\e[36mBeginning DESTROY\e[0m"
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    ruby logic.rb reset &&
    export COMPOSE_FILE= &&
    export COMPOSE_PROJECT_NAME= &&
    source scripts/add-aliases.sh &&
    source scripts/remove-aliases.sh
fi

if [ "$command" = "repair" ]
then
    echo -e "\e[36mBeginning REPAIR\e[0m"
    ruby logic.rb prepare-compose-environment &&
    source scripts/prepare-docker.sh &&
    source scripts/add-aliases.sh
fi
