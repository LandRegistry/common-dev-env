#!/bin/bash
set -e
host="$1"

# Basically wait until a psql command completes successfully (checking for the existance of a database called postgres in the output)
until docker exec postgres bash -c 'pg_isready -h localhost' ; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done
echo "Postgres is ready"