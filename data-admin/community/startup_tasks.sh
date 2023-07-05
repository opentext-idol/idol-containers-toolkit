#!/bin/bash

source /community/startup_utils.sh

SERVERNAME=community
CONTENT_HOST=idol-passageextractor-content
CONTENT_PORT=9100
AGENTSTORE_HOST=idol-qms-agentstore
AGENTSTORE_PORT=20050

local AESKEYFILE=/$SERVERNAME/aes.keyfile
if [ -e $AESKEYFILE ]
then
    echo "Found AES keyfile"
else
    /$SERVERNAME/autpassword.exe -x -tAES -oKeyFile=$AESKEYFILE
fi

waitForAci $CONTENT_HOST:$CONTENT_PORT
waitForAci $AGENTSTORE_HOST:$AGENTSTORE_PORT