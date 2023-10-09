#!/bin/bash

U=localhost:9130
TENANT=fs0904
username=system_user
password=system
admin_user=testing_admin
admin_password=admin

login_admin() {
	curl -s -Dheaders -HX-Okapi-Tenant:testlib14 -HContent-Type:application/json -d"{\"username\":\"$admin_user\",\"password\":\"$admin_password\"}" $U/authn/login
token=`awk '/x-okapi-token/ {print $2}' <headers|tr -d '[:space:]'`
}

okapi_curl() {
	if test "$1" != "x"; then
		local OPT="-HX-Okapi-Token:$token"
	else
		local OPT="-HX-Okapi-Tenant:$TENANT"
	fi
	shift
	curl -s $OPT -HAuthtoken-Refresh-Cache:true -HContent-Type:application/json $*
}

make_system_user() {
	local username=$2
	local password=$3
	
	uid=`uuidgen`
	okapi_curl $1 -XDELETE "$U/users?query=username%3D%3D$username"
	okapi_curl $1 -d"{\"username\":\"$username\",\"id\":\"$uid\",\"active\":true}" $U/users
	okapi_curl $1 -d"{\"username\":\"$username\",\"userId\":\"$uid\",\"password\":\"$password\"}" $U/authn/credentials
	puid=`uuidgen`
	okapi_curl $1 -d"{\"id\":\"$puid\",\"userId\":\"$uid\",\"permissions\":[\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $U/perms/users
}

login_sys_user() {
	local username=$2
	local password=$3
	
	curl -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/authn/login -HX-Okapi-Tenant:$TENANT -HContent-Type:application/json -HAuthtoken-Refresh-Cache:true 
}

echo "Logging in admin"
login_admin

echo "Token after login is $token"

echo "Creating tenant $TENANT"
curl -d"{\"id\":\"$TENANT\",\"name\":\"$TENANT\",\"description\":\"$TENANT\"}" $U/_/proxy/tenants -HX-Okapi-Token:$token -HAuthtoken-Refresh-Cache:true -HContent-Type:application/json

echo "Enabling modules to $TENANT"
curl -d"[{\"id\":\"mod-users-19.2.0-SNAPSHOT\",\"action\":\"enable\"},{\"id\":\"mod-login-7.10.0-SNAPSHOT\",\"action\":\"enable\"},{\"id\":\"mod-permissions-6.4.0-SNAPSHOT\",\"action\": \"enable\"},{\"id\":\"mod-configuration-5.9.2-SNAPSHOT\",\"action\":\"enable\"}]" $U/_/proxy/tenants/$TENANT/install -HAuthtoken-Refresh-Cache:true

echo "Creating system user"
make_system_user x $username $password

echo "Enabling mod authtoken for tenant $TENANT"
curl -d"[{\"id\":\"mod-authtoken-2.14.0-SNAPSHOT\",\"action\":\"enable\"}]" $U/_/proxy/tenants/$TENANT/install -HAuthtoken-Refresh-Cache:true

echo "Logging in system user to $TENANT"
login_sys_user x $username $password