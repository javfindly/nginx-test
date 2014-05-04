#!/bin/bash

source enviroments.sh
source helper_functions.sh

stop_nginx
stop_dnsmasq

start_dnsmasq
start_nginx
