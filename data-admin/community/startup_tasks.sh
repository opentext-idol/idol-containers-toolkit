#!/bin/bash

SERVERNAME=community
CONTENT_HOST=idol-passageextractor-content
CONTENT_PORT=9100
AGENTSTORE_HOST=idol-qms-agentstore
AGENTSTORE_PORT=20050

COMMUNITY_PORT=9030

ADMIN_USERNAME=admin
ADMIN_PASSWORD=lLuJBjv38ADR

isAciAvailable() {
    # $1 host, $2 port
    wget -qO- http://$1:$2/a=getpid | grep "SUCCESS"
    return $?
}

waitForAci() {
    echo "Waiting for $1 ACI to be available"
    isAciAvailable $1 $2
    while [ $? -ne 0 ]
    do
        sleep 1
        isAciAvailable $1 $2
    done
}


function pre_startup_tasks {
    local AESKEYFILE=/$SERVERNAME/aes.keyfile
    if [ -e $AESKEYFILE ]
    then
        echo "Found AES keyfile"
    else
        /$SERVERNAME/autpassword.exe -x -tAES -oKeyFile=$AESKEYFILE
    fi

    waitForAci $CONTENT_HOST $CONTENT_PORT
    waitForAci $AGENTSTORE_HOST $AGENTSTORE_PORT
}

function post_startup_tasks {
    waitForAci "localhost" $COMMUNITY_PORT

    local ADDUSER_OUTPUT=adduser.admin.xml

    if [ -e $ADDUSER_OUTPUT ]
    then
        echo "Community already bootstrapped"
    else
        echo "Bootstrapping Community"
        wget -qO $ADDUSER_OUTPUT "localhost:$COMMUNITY_PORT/a=UserAdd&userName=$ADMIN_USERNAME&password=$ADMIN_PASSWORD"
        for role in FindUser FindAdmin FindBI
        do
            wget -qO addrole.$role.xml "localhost:$COMMUNITY_PORT/a=RoleAdd&roleName=$role"
            wget -qO addrole.$role.admin.xml "localhost:$COMMUNITY_PORT/action=RoleAddUserToRole&RoleName=$role&userName=$ADMIN_USERNAME"
        done
    fi
}