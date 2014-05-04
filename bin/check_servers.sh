#!/bin/bash
#
# Utilizando la api de melicloud para controla que todos los servers que estan en nginx esten en la api.
# 
# Ejecutar desde el raiz del repo bin/check_servers.sh
#
#

UPSTREAMS_FILE=upstreams/upstreams.conf
RULES_FILE=subdomains/subdomains.conf

function getPool () {
	server=$1
	cat $UPSTREAMS_FILE| grep $server -B 50 | grep upstream | tail -1 | awk '{print $2}'
}

BEFORE=$(date +%s)

echo "Checking server existence"
rm -f /tmp/servers.20X
rm -f /tmp/servers.40X

touch /tmp/servers.20X 
touch /tmp/servers.40X 

servers=`cat $UPSTREAMS_FILE | egrep "server.*:" | egrep -v 'i-00000104-nsm.melicloud.com|backup|empty|mercadopago.com|mercadoli(b|v)re|slvmx|slvmy|static.com|dblvm|melidynamic.com|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' |  egrep -v '^[[:space:]]*#'| awk '{print $2}' | awk -F':' '{print $1}' | sort | uniq`

#Download servers
servers_api=/tmp/servers.$RANDOM

curl --silent -H 'Accept: text/plain' -X GET http://api.melicloud.com/compute/instances > $servers_api

for server in $servers; do
	if grep -q "$server" $servers_api; then
		printf "\033[32m\033[1m%s\033[0m" "."
		echo "$server" >> /tmp/servers.20X
	else
		printf "\033[31m\033[1m%s\033[0m" "x"
		echo "$server" >> /tmp/servers.40X
	fi
done

echo

OK=`cat /tmp/servers.20X | wc -l`
NOT_FOUND=`cat /tmp/servers.40X | wc -l`

AFTER=$(date +%s)

printf "\n%4s\033[32m %s\033[0m\n" $OK "OK"
printf "%4s\033[33m %s\033[0m\n" $NOT_FOUND "NOT FOUND"
printf "Elapsed: %s seconds\n\n" $(expr $AFTER - $BEFORE)


if [ ! $NOT_FOUND -eq 0 ]; then
	echo "Servers no encontrados:"
	for server in `cat /tmp/servers.40X`; do
		pool=$(getPool $server)
		echo "	$server --> $pool"
	done
	echo "¿¿¿¿Tenes actualizado tu fork????."
	echo
	exit 1;
fi

BEFORE=$(date +%s)

echo "Controlando existencia de pooles..."
rm -f /tmp/pool.20X
rm -f /tmp/pool.40X

touch /tmp/pool.20X 
touch /tmp/pool.40X 

pools=$(cat $RULES_FILE | grep proxy_pass | egrep -v '#' | awk -F'http://' '{print $2}' | sed 's/[;}]//g' | sed 's/:8080//g' | egrep -v '\$|files.melicloud.com|internal.mercadolibre.com|swift.melicloud.com' | sed 's/break//g' | sed 's/ //g' | sort | uniq)

for pool in $pools; do
	if grep -q "$pool" ${UPSTREAMS_FILE}; then
		printf "\033[32m\033[1m%s\033[0m" "."
		echo "$pool" >> /tmp/pool.20X
	else
		if grep -q "$pool" $servers_api; then
			printf "\033[32m\033[1m%s\033[0m" "."
		else
			printf "\033[31m\033[1m%s\033[0m" "x"
			echo "$pool" >> /tmp/pool.40X
		fi
	fi
done

OK=`cat /tmp/pool.20X | wc -l`
NOT_FOUND=`cat /tmp/pool.40X | wc -l`

AFTER=$(date +%s)

printf "\n%4s\033[32m %s\033[0m\n" $OK "OK"
printf "%4s\033[33m %s\033[0m\n" $NOT_FOUND "NOT FOUND"
printf "Elapsed: %s seconds\n\n" $(expr $AFTER - $BEFORE)


if [ ! $NOT_FOUND -eq 0 ]; then
	echo "Pooles o servers en $RULES_FILE no encontrados en la api o $UPSTREAMS_FILE:"
	for pool in `cat /tmp/pool.40X`; do
		echo "	$pool"
	done
	echo "¿¿¿¿Tenes actualizado tu fork????."
	echo 
	exit 1;
fi

