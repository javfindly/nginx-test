#!/bin/bash
FROM=$1
TO=$2
SUBJECT=$3
MESSAGE=$4
TELNET=$(which telnet)
(  echo helo zxc
   /bin/sleep 1
   echo 'mail from:'$FROM
   /bin/sleep 1
   echo 'rcpt to:'$TO
   /bin/sleep 1
   echo data
   /bin/sleep 1
   echo Subject:$SUBJECT
   /bin/sleep 1
   echo From:$FROM
   /bin/sleep 1
   echo To:$TO
   /bin/sleep 5
   echo
   echo -e $MESSAGE
   echo
   echo 
   /bin/sleep 5
   echo .
   /bin/sleep 2
  echo quit
) | $TELNET 172.16.0.128 25

