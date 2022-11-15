#!/usr/bin/env bash
unalias dc
unalias stop
unalias start
unalias restart
unalias rebuild
unalias remove
unalias logs
unalias livelogs
unalias ex
unalias status
unalias run
unalias psql13
unalias db2co
unalias cadence-cli

unset -f bashin
unset -f unit-test
unset -f integration-test
unset -f acceptance-test
unset -f lint
unset -f format
unset -f acctest
unset -f acceptance-lint
unset -f acclint
unset -f manage
unset -f fullreset
unset -f alembic
unset -f localstack
unset -f add-to-docker-compose
unset -f devenv-help

unset DEV_ENV_ROOT_DIR
