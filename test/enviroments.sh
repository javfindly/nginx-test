#!/bin/bash
PID_FILE_DNSMASQ=/tmp/dnsmasq.pid

if [ -d /opt/nginx ]; then
	NGINX=/opt/nginx/sbin/nginx
else
	NGINX=$(which nginx)
fi

DOMAIN=api.mercadolibre.com
DOMAIN_PORT=8080
UPSTREAM=internal.mercadolibre.com.priv.net
METHODS=( GET POST PUT DELETE OPTIONS )
AB_COMMAND=$(which ab)
HTTPERF_COMMAND=$(which httperf)
HTTPERF_TMP_URLS="./httperf_casessh_urls"
