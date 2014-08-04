#!/bin/bash -x
##  METHOD DOMAIN RESOURCE EXPECTED_UPSTREAM

#Multiple domains
test_rule all_fe [www.mydomain.com,mydomain.com] "/" main-upstream

#Someurl
test_rule all_fe www.mydomain.com "/someurl" someurl-upstream

#Different domains
test_rule all_fe mobile.mydomain.com "/" mobile-upstream

#Specific methods
test_rule POST postonly.mydomain.com "/" main-upstream

#Test headers
test_rule GET www.mydomain.com "/" main-cookie-upstream "Cookie:'test=cookie'"
