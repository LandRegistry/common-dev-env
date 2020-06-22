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
