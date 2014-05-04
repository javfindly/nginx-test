#!/bin/bash


echo > /tmp/testok
echo > /tmp/testfailed
echo > /tmp/testnot_found

## Exit codes
# OK
EXIT_OK=0
# FAIL
EXIT_EX_UNAVAILABLE=69
# NOT FOUND
EXIT_EX_TEMPFAIL=75

CURL_MODIFIERS=""

if [ -z $CONCURRENTS_CALLS ]; then
	CONCURRENTS_CALLS=50
fi

ALL_METHODS=$(echo "GET,OPTIONS,POST,PUT,DELETE" | tr "," "\n" ) 
ALL_METHODS_FE=$(echo "GET,POST" | tr "," "\n" ) 

REGEX_PARENTHESES="(.*)\[(.*)\]"

CASE_LINE=3

function close () {
    stop 2>/dev/null 1>/dev/null
    ps -ef |grep $$ | egrep -v "ps|grep|run_test|awk" | awk '{system("kill -9 "$2 > /dev/null)}'
}

function ctrl_c() {
    echo 
    echo "Control-C recibido...matando todo..."
    close
    exit 1
}

function stop() {
    stop_nginx
    stop_dnsmasq
    i=0
    for ip in `grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' ../upstreams/upstreams.conf`; do
        ifconfig lo:$i down
        i=$((i + 1)) 
    done	
}

function start() {
    i=0
    for ip in `grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' ../upstreams/upstreams.conf`; do
        ifconfig lo:$i $ip netmask 255.255.255.255 
        i=$((i + 1)) 
    done
    start_dnsmasq
    wait_dnsmasq
    start_nginx
    wait_nginx
}

function wait_nginx () {
	for i in {1..10}; do
		nginx=$(ps -efa | grep $NGINX | grep -v grep)
		if [ -z "$nginx" ]; then
			sleep 0.5;
		else
			return;
		fi
	done
	echo "Nginx no se pudo levantar."
	close
	exit 1;
}

function wait_dnsmasq () {
	for i in {1..10}; do
		response=$(ping -c 1 lala${RANDOM} 2>&1)
		if echo $response | grep unknown -q; then
			sleep 0.5;
		else
			return;
		fi
	done
	echo "Dnsmasq no se pudo levantar."
	close
	exit 1;
}

function abspath() {
  pushd . > /dev/null
  if [ -d "$1" ]; 
  then 
    cd "$1"
    dirs -l +0
  else 
    cd "`dirname \"$1\"`"
    cur_dir=`dirs -l +0`
    if [ "$cur_dir" == "/" ]; 
    then 
      echo "$cur_dir`basename \"$1\"`"
    else 
      echo "$cur_dir/`basename \"$1\"`"
    fi
  fi
  popd > /dev/null
}

function stop_dnsmasq() {
    test -f $PID_FILE_DNSMASQ && kill $(cat $PID_FILE_DNSMASQ)
    rm -f $PID_FILE_DNSMASQ
    local  PID_DNSMASQ=`ps -ef|grep dnsmasq|grep -v grep| awk '{print $2}'`

    if [ "$PID_DNSMASQ" != "" ]; then
        echo "Dnsmasq is running. (Pid: $PID_DNSMASQ).?"
        kill -9 $PID_DNSMASQ
    fi
}

function start_dnsmasq() {
    stop_dnsmasq
    DNSMASQ=$(which dnsmasq)
    $DNSMASQ --no-hosts --no-resolv --cache-size=5000 --pid-file=$PID_FILE_DNSMASQ --listen-address=127.0.0.1 --address=/#/127.0.0.1 --address=/#/127.0.0.1 & 
}


function start_nginx() {
    ($NGINX -s reload 2>/dev/null) || $NGINX -c $(abspath nginx.conf)
}

function stop_nginx() {
    $NGINX -c $(abspath nginx.conf) -s stop
}

function test_rule_with_content() {
    _test_rule_with_content "$@" &
}

function _test_rule_with_content () {
  local method=$1
  local domain=$2
  local uri=$3
  local pool=$4
  local size=$5
  local file="/tmp/`echo $RANDOM`"
  rm -f $file >/dev/null 
  dd if=/dev/zero of=$file bs=${size} count=1 1>/dev/null 2>/dev/null
  local RESPONSE=$(curl $CURL_MODIFIERS --write-out %{http_code} --silent --output /dev/null -X ${method} -F file=@$file -H "X-Assert-Pool:${pool}" "http://${domain}:$DOMAIN_PORT${uri}")
  rm -f $file >/dev/null
  print_result $RESPONSE "$@"
}


function test_rule_by_method() {
  local method=$1
  local domain=$2
  local uri=$3
  local pool=$4
  local header=$5

  if [ -z $5 ]; then
    local RESPONSE=$(curl $CURL_MODIFIERS --write-out %{http_code} --silent --output /dev/null -X ${method} -H "Content-Length: 0" -H "X-Assert-Pool:${pool}" "http://${domain}:$DOMAIN_PORT${uri}")
  else
    local RESPONSE=$(curl $CURL_MODIFIERS --write-out %{http_code} --silent --output /dev/null -X ${method} -H ${header} -H "Content-Length: 0" -H "X-Assert-Pool:${pool}" "http://${domain}:$DOMAIN_PORT${uri}")
  fi
  print_result $RESPONSE "$@"

}


function test_rule_fail() {
	_test_rule_fail "$@" &
}

function ok () {
	echo "1">>/tmp/testok
}

function failed () {
	echo "1">>/tmp/testfailed
}

function not_found () {
	echo "1">>/tmp/testnot_found
}

function test_status() {
	_test_status "$@" &
}

function _test_status() {
  local domain=$1
  local uri=$2
  local status=$3
  shift
  shift
  shift
  local RESPONSE=$(curl $CURL_MODIFIERS --write-out %{http_code} --silent --output /dev/null "http://$domain:$DOMAIN_PORT$uri" "$@")
  if [ "$RESPONSE" -eq "$status" ]; then
    printf "\033[32m\033[1m%s\033[0m" "."
    ok
  else
    rnd=$RANDOM
    printf "\033[31m\033[1m%s\033[0m" "x"
    printf "\n\e[1;31m%-24s\033[31m\033[1m%-18s\033[0m%s" "(Line ${BASH_LINENO[1]} cases.sh)" "STATUS FAILED" "$domain$uri -> return status $RESPONSE not match with status $status" > $logs_dir/$rnd.err
    failed
  fi
	

}

function _test_rule_fail() {
  local method=$1
  local domain=$2
  local uri=$3
  local pool=$4
  local header=$5

  if [ -z $header ]; then
	header="1=1"
  fi

  local RESPONSE=$(curl $CURL_MODIFIERS --write-out %{http_code} --silent --output /dev/null -X $method -H $header -H "Content-Length: 0" -H "X-Assert-Pool:$pool" "http://$domain:$DOMAIN_PORT$uri")

  if [ "$RESPONSE" -eq "200" ]; then
    printf "\033[31m\033[1m%s\033[0m" "x"
    printf "\n\n\e[1;31m%-20s\033[31m\033[1m%-13s\033[0m%-10.10s%-10s%5s \033[31m%s\033[0m\n" "(Line ${BASH_LINENO[1]} cases.sh)" "FAILED" $method $domain$uri " --> Must not match with " $pool > $logs_dir/$RANDOM.err
    failed
  else
    printf "\033[32m\033[1m%s\033[0m" "."
    ok
  fi
}

function print_result () {
  #Parametros por defecto
  rnd=$RANDOM
  local response=$1
  shift
  local method=$1
  shift
  local domain=$1
  shift
  local uri=$1
  shift
  local pool=$1
  shift

  if [ $response -eq "200" ]; then
    printf "\033[32m\033[1m%s\033[0m" "."
    ok
  else
    printf "\033[31m\033[1m%s\033[0m" "x"

    if [ $response -eq "404" ]; then
      printf "\n\e[1;31m%-20s\e[m\033[33m\033[1m%-13s\033[0m%-10.10s%-10s%5s%s\n" "(Line ${BASH_LINENO[$CASE_LINE]} cases.sh)" "NOT FOUND" $method $domain$uri " --> " $pool >> $logs_dir/$rnd.err
      not_found
    elif [ $response -eq "204" ]; then
      printf "\n\e[1;31m%-20s\e[m\033[31m\033[1m%-13s\033[0m%-10.10s%-10s%5sexpected '\033[31m%s\033[0m' but was '\033[31m%s\033[0m'\n" "(Line ${BASH_LINENO[$CASE_LINE]} cases.sh)" "FAILED" $method $domain$uri " --> " $pool $(get_error $method $uri $pool $domain "$@") >> $logs_dir/$rnd.err
      failed
    else
      printf "\n\e[1;31m%-20s\e[m\033[31m\033[1m%-13s\033[0m%-10.10s%-10s%5sexpected '\033[31m%s\033[0m' status '\033[31m%s\033[0m'\n" "(Line ${BASH_LINENO[$CASE_LINE]} cases.sh)" "FAILED" $method $domain$uri " --> " $pool $response >> $logs_dir/$rnd.err
      failed
    fi
  fi
}

function get_error() {
  if [ -z $5 ]; then
    local ERROR=$(curl $CURL_MODIFIERS --silent -i -X $1 -H "X-Assert-ML-Pool:$3" "http://$4:$DOMAIN_PORT$2" | grep -Po '(?<=^X\-Pool: )[^\.]*')
  else
    local ERROR=$(curl $CURL_MODIFIERS --silent -i -X $1 -H $5 -H "X-Assert-ML-Pool:$3" "http://$4:$DOMAIN_PORT$2" | grep -Po '(?<=^X\-Pool: )[^\.]*')
  fi
  echo "$ERROR" | sed -e 's/\r//g' | sed 's/\n//g'
}

function exit_with_summary() {
  OK=`cat /tmp/testok | wc -w`
  NOT_FOUND=`cat /tmp/testnot_found | wc -w`
  FAILED=`cat /tmp/testfailed | wc -w`
  printf "\n\n%4s\033[32m %s\033[0m\n" $OK "OK"
  printf "%4s\033[33m %s\033[0m\n" $NOT_FOUND "NOT FOUND"
  printf "%4s\033[31m %s\033[0m\n\n" $FAILED "FAILED"
  printf "Elapsed: %s seconds\n\n\n" $1
  if [ $FAILED -gt 0 ]; then
    exit $EXIT_EX_UNAVAILABLE
  elif [ $NOT_FOUND -gt 0 ]; then
    exit $EXIT_EX_TEMPFAIL
  else
    exit $EXIT_OK
  fi
}

function test_rule_with_redirects() {
  CURL_MODIFIERS=" -L"
  test_rule "$@"
}

calls=0

function test_rule(){
    _test_rule "$@" &
}
function _test_rule(){
	local method=$1;
	local domain=$2;
	local uri=$3;
	local pool=$4;
	shift;
	shift;
	shift;
	shift;

     if [[ $domain =~ $REGEX_PARENTHESES  ]]; then
        local str=$(echo $domain| awk -F "[" '{print $2}'| awk -F "]" '{print $1}')
        local subdom=$(echo $domain| awk -F "[" '{print $1}')
    else
        local subs=$domain
    fi

    if [[ $method == "all" ]]; then
 	local meth=$ALL_METHODS
    else 
	if [[ $method == "all_fe" ]]; then
		local meth=$ALL_METHODS_FE
	else
		local meth=$(echo $method | tr "," "\n" )
    	fi
    fi

    for sub in $subs; do
    	for m in $meth; do
	    	test_rule_by_method $m $sub $uri $pool "$@"
    	done
    done
    wait
}


