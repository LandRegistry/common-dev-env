if [ -f dev-env-config/after-up.sh ]; then
    echo -e "\e[33m*******************************************************\e[0m"
    echo -e "\e[33m**                                                   **\e[0m"
    echo -e "\e[33m**                     WARNING!                      **\e[0m"
    echo -e "\e[33m**                                                   **\e[0m"
    echo -e "\e[33m*******************************************************\e[0m"
    echo -e "\e[33mThe dev-env specific after-up script is deprecated and will be removed in a future update.\e[0m"
    echo -e "\e[33mPlease use an application-specific custom-provision-always.sh instead\e[0m"
    echo -e "\e[36mRunning after-up script from dev-env-config\e[0m"

    . dev-env-config/after-up.sh
fi

if [ -f dev-env-config/after-up-once.sh ] && [ ! -f .after-up-once ]; then
    echo -e "\e[33m*******************************************************\e[0m"
    echo -e "\e[33m**                                                   **\e[0m"
    echo -e "\e[33m**                     WARNING!                      **\e[0m"
    echo -e "\e[33m**                                                   **\e[0m"
    echo -e "\e[33m*******************************************************\e[0m"
    echo -e "\e[33mThe dev-env specific after-up-once script is deprecated and will be removed in a future update.\e[0m"
    echo -e "\e[33mPlease use an application-specific custom-provision.sh instead\e[0m"
    echo -e "\e[36mRunning after-up-once script from dev-env-config\e[0m"

    . dev-env-config/after-up-once.sh

    echo "done" > .after-up-once
fi

