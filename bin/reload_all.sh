#!/bin/bash -l
SERVERS_FILE=$1
servers=( `cat $SERVERS_FILE | grep -v "#" | tr "\n" " "`)
for ws in ${servers[*]}; do
  echo "ssh $ws /department/api/bin/reload.sh"
  ssh $ws /department/api/bin/reload.sh
  sleep 2
done
