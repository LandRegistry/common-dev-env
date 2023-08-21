#!/bin/bash

cleanup() {
    /opt/mqm/bin/endmqweb
    exit
}

trap cleanup INT TERM

runmqdevserver
