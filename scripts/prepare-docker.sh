# Export the current user such that it can be used inside docker compose fragments
# When creating files inside the docker container, this prevents the files being created
# as the root user on linux hosts
export CURRENT_USER=$(id -u):$(id -g)

# In WSL, we need to make sure our environment variables are passed to Docker for Windows' executables
# (If symlinks to the exe's are being used rather than native client --> TCP connection)
if grep -q Microsoft /proc/version; then
  if [ -z "${WSLENV_SET+x}" ]; then
    echo -e "\e[36mWindows Subsystem for Linux detected; adding to WSLENV environment variable\e[0m"
    export WSLENV="COMPOSE_FILE/l:COMPOSE_PROJECT_NAME${WSLENV:+:${WSLENV}}"
    export WSLENV_SET=yes
  fi
fi

# Got to use a constant project name to ensure that containers are properly tracked regardless of how fragments are added are removed. Otherwise you get duplicate errors on the build
export COMPOSE_PROJECT_NAME=dv

# Load all the docker compose file references that were saved earlier
dockerfilelist=$(<./.docker-compose-file-list)
export COMPOSE_FILE=$dockerfilelist

echo "- - - Removing any orphaned docker volumes - - -"
volumes=$(docker volume ls -qf dangling=true)
if [ -n "$volumes" ]; then
  docker volume rm `docker volume ls -q -f dangling=true`
fi

echo "- - - Removing any orphaned docker images - - -"
images=$(docker images -f dangling=true -q)
if [ -n "$images" ]; then
  docker rmi -f `docker images -f dangling=true -q`
fi

# If there's docker apps (the var is not empty), then do docker stuff
if ! [ -z "$COMPOSE_FILE" ]; then
  # Only "up" creates network so lets create it here first in case someone does a "start"
  if docker network ls | grep -q "dv_default"; then
    echo "Docker network already exists, skipping creation"
  else
    docker network create dv_default
  fi
fi
