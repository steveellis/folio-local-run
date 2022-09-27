#!/bin/bash

set -e
U=http://localhost:9130
T=testlib14
username=testing_admin
password=admin
curl -d"{\"id\":\"$T\"}" $U/_/proxy/tenants
curl -d'{"name":"DB_HOST","value":"localhost"}' $U/_/env
curl -d'{"name":"DB_PORT","value":"5432"}' $U/_/env
curl -d'{"name":"DB_USERNAME","value":"postgres"}' $U/_/env
curl -d'{"name":"DB_PASSWORD","value":"postgres3636"}' $U/_/env
curl -d'{"name":"DB_DATABASE","value":"postgres"}' $U/_/env
curl -d'{"name":"KAFKA_PORT","value":"9092"}' $U/_/env
curl -d'{"name":"KAFKA_HOST","value":"localhost"}' $U/_/env
curl -d"{\"name\":\"OKAPI_URL\",\"value\":\"$U\"}" $U/_/env
curl -d'{"name":"ELASTICSEARCH_URL","value":"http://localhost:9200"}' $U/_/env

# Set of modules that are necessary to bootstrap admin user
CORE_MODULES="mod-users mod-login mod-permissions mod-configuration"

#TEST_MODULES="mod-users-bl"
#TEST_MODULES="mod-users-bl mod-password-validator"
TEST_MODULES="mod-inventory-storage mod-password-validator mod-event-config mod-pubsub mod-circulation-storage mod-template-engine mod-email mod-sender mod-notify mod-users-bl mod-search"

compile_module() {
	local m=$1
	if test ! -d $m; then	
		git clone --recurse-submodules git@github.com:folio-org/$m

	fi
	if test ! -d $m; then
		echo "$m missing. git clone failed?"
		exit 1
	fi
	cd $m
	mvn -DskipTests -Dmaven.test.skip=true verify
	cd ..
}

register_module() {
	local m=$2
	echo "Register module $m"
	local md=$m/target/ModuleDescriptor.json
	if test ! -f $md; then
		compile_module $m
	fi
	if test ! -f $md; then
		echo "$md missing pwd=`pwd`"
		exit 1
	fi
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	curl -s $OPT -d@$md $U/_/proxy/modules -o /dev/null
	local dd=$m/target/DeploymentDescriptor.json
}

deploy_module() {
	local m=$2
	echo "Deploy module $m"
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	local dd=$m/target/DeploymentDescriptor.json
	curl -s $OPT -d@$dd $U/_/deployment/modules -o /dev/null
}

deploy_modules() {
	for m in $2; do
		register_module $1 $m
	done
	for m in $2; do
		deploy_module $1 $m
	done
}

install_modules() {
	local j="["
	local sep=""
	for m in $3; do
		j="$j $sep {\"action\":\"$2\",\"id\":\"$m\"}"
		sep=","
	done
	j="$j]"
	if test "$1" != "x"; then
		OPT=-HX-Okapi-Token:$1
	else
		OPT=""
	fi
	echo "installing $j"
	curl -s $OPT "-d$j" "$U/_/proxy/tenants/$T/install?purge=true"
}

okapi_curl() {
	if test "$1" != "x"; then
		local OPT="-HX-Okapi-Token:$1"
	else
		local OPT="-HX-Okapi-Tenant:$T"
	fi
	shift
	curl -s $OPT -HAuthtoken-Refresh-Cache:true -HContent-Type:application/json $*
}

make_adminuser() {
	local username=$2
	local password=$3
	
	uid=`uuidgen`
	echo "uid is $uid"
	okapi_curl $1 -XDELETE "$U/users?query=username%3D%3D$username"
	okapi_curl $1 -d"{\"username\":\"$username\",\"id\":\"$uid\",\"active\":true}" $U/users
	okapi_curl $1 -d"{\"username\":\"$username\",\"userId\":\"$uid\",\"password\":\"$password\"}" $U/authn/credentials
	puid=`uuidgen`
	okapi_curl $1 -d"{\"id\":\"$puid\",\"userId\":\"$uid\",\"permissions\":[\"okapi.all\",\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $U/perms/users
}

login_admin() {
	curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/authn/login
token=`awk '/x-okapi-token/ {print $2}' <headers|tr -d '[:space:]'`
}

login_with_expiry() {
	curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/authn/login-with-expiry -v
}

login_users_bl() {
	curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/bl-users/login -v
}

login_users_bl_expand_perms() {
	curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/bl-users/login?expandPermissions=true -v
}


deploy_modules x "$CORE_MODULES"

deploy_modules x mod-authtoken

install_modules x enable "$CORE_MODULES"
install_modules x enable okapi

make_adminuser x $username $password

install_modules x enable mod-authtoken

login_admin

deploy_modules $token "$TEST_MODULES"

sleep 5

install_modules $token enable "$TEST_MODULES"

sleep 5

okapi_curl $token $U/perms/users/$puid/permissions -d'{"permissionName":"users-bl.all"}'

#login_admin

#login_with_expiry

# Run with source to get this in the env.
export TOKEN=$token

# Gotta sleep a little bit still to see things that depend on the perm be set.
sleep 2

login_users_bl

#login_users_bl_expand_perms

# Try out

newpassword=P%assw0rd1

# echo "Changing password"
# curl -s -HX-Okapi-Token:$token $U/bl-users/settings/myprofile/password -HContent-Type:application/json -d"{\"userId\":\"$uid\",\"username\":\"$username\",\"password\":\"$password\",\"newPassword\":\"$newpassword\"}" -v

echo "Generating reset link"
okapi_curl $token $U/bl-users/password-reset/link -d"{\"userId\":\"$uid\"}" -o reset.json

# The token can be obtained from the reset link.
token2=`jq -r '.link' < reset.json |sed -e 's@.*reset-password/@@'`

echo "Validating password"
curl -s -HX-Okapi-Token:$token2 $U/bl-users/password-reset/validate -d'{}' -v

echo "Resetting password"
curl -s -HX-Okapi-Token:$token2 $U/bl-users/password-reset/reset -HContent-Type:application/json -d"{\"newPassword\":\"$newpassword\"}" -v

echo "Logging in with new password"
curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$newpassword\"}" $U/bl-users/login -v
