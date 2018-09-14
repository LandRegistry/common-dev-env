#!/bin/bash
set -e
host="$1"

# Basically wait until a psql command completes successfully (checking for the existance of a database called postgres in the output)
until docker exec postgres bash -c 'psql -h "$host" -U "root" -lqt | cut -d \| -f 1 | grep -qw postgres' ; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
echo "Postgres is ready"