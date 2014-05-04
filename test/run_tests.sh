#!/bin/bash

set -m # Enable Job Control

source enviroments.sh
source helper_functions.sh

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT


BEFORE=$(date +%s)

start

logs_dir=/tmp/`date +%s`
mkdir -p $logs_dir

source cases.sh

wait
echo
cat $logs_dir/* 2>/dev/null
rm -rf $logs_dir
stop

AFTER=$(date +%s)
exit_with_summary $(expr $AFTER - $BEFORE)

