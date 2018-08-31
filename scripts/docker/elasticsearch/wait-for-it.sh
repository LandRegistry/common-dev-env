#!/bin/bash
set -e
host="$1"

# Basically wait until it returns a 200 http code
until [ "200" == `curl --write-out "%{http_code}" --silent --output /dev/null $host` ] ; do
  >&2 echo "Elasticsearch is unavailable - sleeping"
  sleep 1
done



echo "Elasticsearch is ready"