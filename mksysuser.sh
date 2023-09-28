#!/bin/bash

U=$OKAPI
T=$TENANT
username=system_user
password=system

okapi_curl() {
	if test "$1" != "x"; then
		local OPT="-HX-Okapi-Token:$TOKEN"
	else
		local OPT="-HX-Okapi-Tenant:$T"
	fi
	shift
	curl -s $OPT -HAuthtoken-Refresh-Cache:true -HContent-Type:application/json $*
}

make_system_muser() {
	local username=$2
	local password=$3
	
	uid=`uuidgen`
	okapi_curl $1 -XDELETE "$U/users?query=username%3D%3D$username"
	okapi_curl $1 -d"{\"username\":\"$username\",\"id\":\"$uid\",\"active\":true}" $U/users
	okapi_curl $1 -d"{\"username\":\"$username\",\"userId\":\"$uid\",\"password\":\"$password\"}" $U/authn/credentials
	puid=`uuidgen`
	okapi_curl $1 -d"{\"id\":\"$puid\",\"userId\":\"$uid\",\"permissions\":[\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $U/perms/users
}

make_system_muser x $username $password