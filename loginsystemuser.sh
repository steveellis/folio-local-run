#!/bin/bash

username=system_user
password=system

login_sys_user() {
	local username=$2
	local password=$3
	
	curl -d"{\"username\":\"username\",\"password\":\"password\"}" http://localhost:9130/authn/login -HX-Okapi-Tenant:fs0904 -HContent-Type:application/json -HAuthtoken-Refresh-Cache:true 
}

login_sys_user x $username $password