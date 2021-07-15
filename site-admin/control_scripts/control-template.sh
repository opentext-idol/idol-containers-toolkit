#!/bin/bash

# Get to correct directory to run <COMPONENT>.
pushd /<COMPONENT> > /dev/null 2>&1

# Include startup tasks and utils
source /<COMPONENT>/startup_tasks.sh

if [ $1 == 'start' ]
then
    pre_startup_tasks

    echo "--------------------------------------------------------------------"
    echo "Micro Focus <COMPONENT> Server"
    echo "(c) 1999-2021 Micro Focus"
    echo "--------------------------------------------------------------------"
    echo "Starting <COMPONENT> Server..."

    /<COMPONENT>/<COMPONENT>.exe -configfile /<COMPONENT>/cfg/<COMPONENT>.cfg &
    serverpid=$!
    echo "Started <COMPONENT> Server with PID $serverpid"

    post_startup_tasks
fi

if [ $1 == 'stop' ]
then
    echo "Stopping <COMPONENT> Server..."
    if [ -f <COMPONENT>.pid ]
    then
        kill -15 `cat <COMPONENT>.pid`
        echo "Stopped <COMPONENT> Server"
        else
        echo "Could not locate <COMPONENT>.pid - unable to stop <COMPONENT> Server"
    fi 
fi

exit

