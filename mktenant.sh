#!/bin/bash

U=$OKAPI
T=$TENANT

curl -d"{\"id\":\"$TENANT\",\"name\":\"$TENANT\",\"description\":\"$TENANT\"}" $U/_/proxy/tenants -HX-Okapi-Token:$TOKEN -HAuthtoken-Refresh-Cache:true -HContent-Type:application/json
