# In WSL, we need to make sure our environment variables are passed to Docker for Windows' executables
# (If symlinks to the exe's are being used rather than native client --> TCP connection)
if grep -qs Microsoft /proc/version; then
  if [ -z "${WSLENV_SET+x}" ]; then
    echo -e "\e[36mWindows Subsystem for Linux detected; adding to WSLENV environment variable\e[0m"
    export WSLENV="OUTSIDE_UID:OUTSIDE_GID:COMPOSE_FILE/l:COMPOSE_PROJECT_NAME${WSLENV:+:${WSLENV}}"
    export WSLENV_SET=yes
  fi
fi

# Got to use a constant project name to ensure that containers are properly tracked regardless of how fragments are added are removed. Otherwise you get duplicate errors on the build
export COMPOSE_PROJECT_NAME=dv

# Set environment variables for compose files to send to Dockerfiles as arguments,
# should the Dockerfile wish to create a matching user to run the container as
# However Git Bash does not care about file system permissions, and uses weirdly high UIDs, so
# just use 1000 in that case
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "win"* || "$OSTYPE" == "cygwin"* ]] ; then
  export OUTSIDE_UID=1000
  export OUTSIDE_GID=1000
else
  export OUTSIDE_UID=$(id -u)
  export OUTSIDE_GID=$(id -g)
fi

# Load all the docker compose file references that were saved earlier
dockerfilelist=$(<./.docker-compose-file-list)
export COMPOSE_FILE=$dockerfilelist

# If there's docker apps (the var is not empty), then do docker stuff
if ! [ -z "$COMPOSE_FILE" ]; then
  # Only "up" creates network so lets create it here first in case someone does a "start"
  if docker network ls | grep -q "dv_default"; then
    echo ""
  else
    docker network create dv_default
  fi
fi
