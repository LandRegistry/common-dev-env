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
