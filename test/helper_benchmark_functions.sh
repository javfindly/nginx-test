let FAILED=0
let OK=0
let NOT_FOUND=0

## Exit codes
# OK
EXIT_OK=0
# FAIL
EXIT_EX_UNAVAILABLE=69
# NOT FOUND
EXIT_EX_TEMPFAIL=75

LOGFILE=benchmark_log.log
echo > $LOGFILE
function test_with_httperf(){
    COMMAND=$1
    DESC=$2
    echo $COMMAND >> $LOGFILE
    RESPONSE=`$COMMAND`
    echo $RESPONSE >> $LOGFILE
    errors=`echo $RESPONSE | gawk 'match($0,/Errors: total *([0-9]*)/,arr) {print arr[1]}'`
    err_500=`echo $RESPONSE | grep "5xx=0"`
    if [[ $errors == "0" && $err_500 != "" && $? -eq 0 ]]; then
       request_rate=`echo $RESPONSE | gawk 'match($0,/(Request rate:.*\/req\))/,arr) {print arr[1]}'`
       conn_data=`echo $RESPONSE | gawk 'match($0,/(Connection time.*).*Connection length/,arr) {print arr[1]}'`
       printf "\033[32mOK\033[0m - $DESC - [$request_rate, $conn_data]\n"
       let OK=OK+1
    else
       printf "\033[31mFAILED\033[0m - $DESC\n"
       let FAILED=FAILED+1
    fi

}

function test_throughput() {
    COMMAND="$HTTPERF_COMMAND --hog --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/EchoServer/echo?responseSize=$3&sleepTime=$4"
    DESC="Test Throughput [throughput: $1, request: $2, responseSize: $3, responseDelay:$4]"
    test_with_httperf "$COMMAND" "$DESC"
}

function test_throughput_with_fails() {
    COMMAND="$HTTPERF_COMMAND --hog --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/EchoServer/echo?responseSize=$3&sleepTime=$4&failPercent=$5"
    DESC="Test Throughput [throughput: $1, request: $2, responseSize: $3, responseDelay:$4,failPercent:$5]"
    test_with_httperf "$COMMAND" "$DESC"
}


##test_balancer_reload throughput(req/seg) amount_of_request response_size(KB) response_delay(ml) sleep_between_reload reloads_amount
function test_balancer_reload(){
	generate_httperf_urls_from_casessh $3 $4 $4 100
	(
		for ((i=0; i<$6; i++ ))
		do
			 sleep $(($5))
			 curl --silent $IP:9006 > /dev/null
		done
	) > /dev/null &
    TIMEOUT=20
    COMMAND="$HTTPERF_COMMAND --hog --timeout=$TIMEOUT --wlog=y,$HTTPERF_TMP_URLS --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/"
    DESC="Test Throughput with balancer Reload (from cases urls) [throughput: $1, request: $2, responseSize: $3, responseDelay:$4, Sleep between reloads $5, Reloads Amount: $6]"
    test_with_httperf "$COMMAND" "$DESC"
    rm $HTTPERF_TMP_URLS	
	
}

function test_throughput_variable_urls() {
    COMMAND="$HTTPERF_COMMAND  --hog --wlog=y,$3 --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/"
    DESC="Test Throughput [throughput: $1, requests: $2]"
    test_with_httperf "$COMMAND" "$DESC"
}

function test_throughput_variable(){
    COMMAND="$HTTPERF_COMMAND --hog --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/EchoServer/echo?responseSize=$3&sleepTime=$4&sleepTime2=$5&sleepTime2_percent=$6"
    DESC="Test Throughput [throughput: $1, request: $2, responseSize: $3, responseDelay:$4, responseDelay2;$5, delay2Percent: $6]"
    test_with_httperf "$COMMAND" "$DESC"
}

function test_concurrency() {
  COMMAND="$AB_COMMAND -q -c $1 -n $2 http://$IP:$PORT/EchoServer/echo?responseSize=$3&sleepTime=$4"
  echo $COMMAND >> $LOGFILE
  RESPONSE=$($COMMAND)
  echo $COMMAND >> $LOGFILE
  failed_requests=`echo $RESPONSE | grep -e "Failed requests: *0"`
  write_errors=`echo $RESPONSE |  grep -e "Write errors: *0"`
  non_200=`echo $RESPONSE |  grep -e "Non-2xx"`
  if [[ $failed_requests != "" && $write_errors != "" && $non_200 == "" ]]; then
     conc=`echo $RESPONSE | gawk 'match($0,/Concurrency Level: *([0-9]*)/,arr) {print arr[1]}'`
     time=`echo $RESPONSE | gawk 'match($0,/Time taken for tests: *(.*) Complete/,arr) {print arr[1]}'`
     printf "\033[32mOK\033[0m - Test Concurrency [concurrency: $1, request: $2, responseSize: $3, responseDelay:$4] -  Real Concurrency: $conc  - Exec Time: $time\n"
     let OK=OK+1
                      
  else
    printf "\033[31mFAILED\033[0m - Test Concurrency [concurrency: $1, request: $2, responseSize: $3, responseDelay:$4]\n"
    let FAILED=FAILED+1
  fi
}

#It receive $1=requestPerSeccond $2=amount of request $3=responseSize $4=sleepTime $5=serverToDownload(only ip) $6=preDownloadSleep(secconds) $7=serverDownSleep(seconds)
function test_down_server_pool_performance(){
    (sleep $6; curl --silent --max-time 6 $5:9005; sleep $7; curl --silent $5:9004) > /dev/null > /dev/null &
    COMMAND="$HTTPERF_COMMAND -v --hog --num-conns=$2 --rate=$1 --server=$IP --port=$PORT --uri=/EchoServer/echo?responseSize=$3&sleepTime=$4"
    DESC="Test Down server Throughput [throughput: $1, request: $2, responseSize: $3, responseDelay:$4]"
    test_with_httperf "$COMMAND" "$DESC"

}

#It will recive $1=concurrency $2=request $3=responseSize $4=sleepTime  $5=server_balance_1 $6=server_balance_2 $7=server_balance_3 $8=threshold
function test_balance(){
	CURL="curl --write-out %{http_code} --silent --output /dev/null"
	$CURL http://$5/clearCounters > /dev/null
	$CURL http://$6/clearCounters > /dev/null
	$CURL http://$7/clearCounters > /dev/null
	$CURL http://$5/putInFailMode > /dev/null
	COMMAND="$AB_COMMAND -q -c $1 -n $2 http://$IP:$PORT/balanceTest?responseSize=$3&sleepTime=$4"
	echo $COMMAND >> $LOGFILE
	RESP=$($COMMAND)
	echo $RESP >> $LOGFILE
	$CURL http://$5/outFailMode > /dev/null
	B1=$(curl --silent http://$6/getCounters | grep requests |tr "requests:" "\0" | tr "," "\0")	
	B2=$(curl --silent http://$7/getCounters | grep requests |tr "requests:" "\0" | tr "," "\0")	
	let MAX=0
	let MIN=0
	if [ "$B1" -le "$B2" ]; then
		let MAX=$B2
		let MIN=$B1
	else
		let MAX=$B1
		let MIN=$B2
	fi
	let T=$((((($MAX-$MIN)*100)/$2)))
	if [ "$T" -le "$8" ]; then
		printf "\033[32mOK\033[0m - Test Balance [Diference between servers: $T%%]"
		let OK=OK+1
	else
		printf "\033[31mFAILED\033[0m - Test Balance [Diference between servers: $T%%]"
		let FAILED=FAILED+1
	fi
	
}

function exit_with_summary_simple() {
  printf "\n\n%4s\033[32m %s\033[0m\n" $OK "OK"
  printf "%4s\033[31m %s\033[0m\n\n" $FAILED "FAILED"
  printf "Elapsed: %s seconds\n\n\n" $1
  if [ $FAILED -gt 0 ]; then
    exit $EXIT_EX_UNAVAILABLE
  else
    exit $EXIT_OK
  fi
}

function generate_httperf_urls_from_casessh(){
    export RESPONSE_SIZE=$1 
    export SLEEP_TIME=$2 
    export SLEEP_TIME2=$3
    export SLEEP_TIME2_PERCENT=$4
    cat cases.sh | tr "[" "-" | tr "]" "-" > $HTTPERF_TMP_CASES
    source $HTTPERF_TMP_CASES
    rm $HTTPERF_TMP_CASES
    
}

