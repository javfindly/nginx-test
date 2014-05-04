#!/bin/bash
source ./test/enviroments.sh


function error(){
	echo "ERROR: $1"
	echo "Please run 'sudo make nginx'"
	exit 1;
}

if [[ $NGINX == "" ]]; then
	error "Nginx not found"
fi


for m in echo-nginx-module ngx_devel_kit set-misc-nginx-module nginx-upstream-idempotent headers-more-nginx-module nginx-x-rid-header lua-nginx-module
do
	MOD=`$NGINX -V 2>&1 | grep "$m"`
	if [[ $MOD == "" ]]; then
		error "Module $m not installed"
	fi
done
