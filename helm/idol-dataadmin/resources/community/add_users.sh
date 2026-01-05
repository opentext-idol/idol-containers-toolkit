#!/bin/bash

source /community/startup_utils.sh

COMMUNITY_PORT={{ .Values.community.aciPort }}

function addDevUser() {
    local USERNAME={{ .Values.dataadminUsername }}
    local PASSWORD={{ .Values.dataadminPassword }}

    if [ -e adduser.dev.xml ]
    then
        echo "Community already has the default users added"
    else
        echo "Adding users to Community"
        for role in AnswerBankUser IDAUser ISOUser ISOAdmin 
        do
            addUserWithRole $USERNAME $PASSWORD $role $COMMUNITY_PORT
        done    
    fi
}

addDevUser