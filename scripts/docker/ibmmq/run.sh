#!/bin/bash

cleanup() {
    /opt/mqm/bin/endmqweb
    exit
}

trap cleanup INT TERM

rm -rf /var/mqm/web/installations/Installation1/servers/.pid
rm -rf /var/mqm/web/installations/Installation1/servers/mqweb/workarea
runmqdevserver
