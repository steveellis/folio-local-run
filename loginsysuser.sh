#!/bin/bash

U=$OKAPI
T=$TENANT
username=system_user
password=system

login_sys_user() {
	local username=$2
	local password=$3
	
	curl -d"{\"username\":\"testing_admin\",\"password\":\"admin\"}" $U/authn/login -HX-Okapi-Tenant:$TENANT -HContent-Type:application/json
}

login_sys_user x $username $password