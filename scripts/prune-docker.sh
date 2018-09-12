
echo "- - - Removing all existing docker containers (and their data volumes) - - -"
docker ps -a -q | xargs docker rm -v -f

echo "- - - Removing all unused docker images, volumes and containers - - -"
docker system prune --all --force --volumes
