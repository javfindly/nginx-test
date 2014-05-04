#!/bin/bash
PID_FILE_DNSMASQ=/tmp/dnsmasq.pid

if [ -d /opt/nginx ]; then
	NGINX=/opt/nginx/sbin/nginx
else
	NGINX=$(which nginx)
fi

DOMAIN_PORT=8080
