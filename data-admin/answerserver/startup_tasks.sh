#!/bin/bash

function wait_for_pg_isready {
    local HOST=$1
    local PORT=$2
    local USER=$3
    local DBNAME=$4
    local SLEEP_TIME=$5
    local MAX_RETRIES=$6

    echo "Waiting for postgres DB $DBNAME on $HOST:$PORT"

    local RETRIES=0

    while :
    do
        if [ ! $RETRIES -lt $MAX_RETRIES ]
        then
            echo "Timeout while waiting for postgres $DBNAME on $HOST:$PORT"
            exit 1
        fi

        pg_isready -d $DBNAME -h $HOST -p $PORT -U $USER --quiet
        case "$?" in
        0     ) return;;
        1 | 2 ) sleep $SLEEP_TIME; RETRIES=$((RETRIES+1));;
        3 | * ) exit 1;;
        esac
    done
}

function pre_startup_tasks {
    wait_for_pg_isready idol-factbank-postgres 5432 postgres factbank-data 1 60
    :
}

function post_startup_tasks {
    :
}