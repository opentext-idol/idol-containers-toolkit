#!/bin/bash

source /community/startup_utils.sh

COMMUNITY_PORT=9030

ADMIN_USERNAME=admin
ADMIN_PASSWORD=lLuJBjv38ADR

waitForAci localhost:$COMMUNITY_PORT

local ADDUSER_OUTPUT=adduser.admin.xml

if [ -e $ADDUSER_OUTPUT ]
then
    echo "Community already bootstrapped"
else
    echo "Bootstrapping Community"
    for role in FindUser FindAdmin FindBI 
    do
        addUserWithRole $ADMIN_USERNAME $ADMIN_PASSWORD $role $COMMUNITY_PORT
    done  
fi
