#!/bin/bash

U=$OKAPI

curl -d"[{\"id\":\"mod-users-19.2.0-SNAPSHOT\",\"action\":\"enable\"},{\"id\":\"mod-login-7.10.0-SNAPSHOT\",\"action\":\"enable\"},{\"id\":\"mod-permissions-6.4.0-SNAPSHOT\",\"action\": \"enable\"},{\"id\":\"mod-configuration-5.9.2-SNAPSHOT\",\"action\":\"enable\"}]" $U/_/proxy/tenants/$TENANT/install -HAuthtoken-Refresh-Cache:true

