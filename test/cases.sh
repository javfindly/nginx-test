#!/bin/bash -x
##  METHOD DOMAIN RESOURCE EXPECTED_UPSTREAM

test_rule all_fe [www.mydomain.com,mydomain.com] "/" main-upstream
test_rule all_fe www.mydomain.com "/someurl" someurl-upstream

test_rule all_fe mobile.mydomain.com "/" mobile-upstream

test_rule POST postonly.mydomain.com "/" main-upstream
