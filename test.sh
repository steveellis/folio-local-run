#!/bin/bash

set -e
U=http://localhost:9130
T=testlib14
username=testing_admin
password=admin

login_users_bl() {
	curl -s -Dheaders -HX-Okapi-Tenant:$T -HContent-Type:application/json -d"{\"username\":\"$username\",\"password\":\"$password\"}" $U/bl-users/login -v
}

login_users_bl