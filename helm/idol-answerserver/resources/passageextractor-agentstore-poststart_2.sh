#!/bin/bash

function wait_for_aci_service {
    local HOST=$1
    local PORT=$2
    local SLEEP_TIME=$3
    local MAX_RETRIES=$4

    local RETRIES=0
    while :
    do
        if [ ! $RETRIES -lt $MAX_RETRIES ]
        then
            echo "Timeout while waiting for ACI service on $HOST:$PORT"
            exit 1
        fi

        curl -s --noproxy -X --head http://$HOST:$PORT/action=getpid
        if [ $? -ne 0 ]
        then
            sleep $SLEEP_TIME
            RETRIES=$((RETRIES+1))
            continue
        else
            break
        fi
    done
}

wait_for_aci_service localhost {{ .Values.passageextractorSingleAgentstore.aciPort | int }} 1 60

for i in `ls idx/*.idx.gz`;
do
    if [ ! -e $i.indexed ];
    then
        echo "Indexing $i"
         curl -s --noproxy -o doc.txt "http://localhost:$(({{ .Values.passageextractorSingleAgentstore.aciPort | int }}+1))/DREADD?/content/$i"
        touch $i.indexed
    fi
done
rm doc.txt*