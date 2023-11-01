#!/bin/bash
set -x -o allexport
grep nifi-0. /etc/hostname
notprimary=$?
if [ 1 == ${notprimary} ]; then
    echo Skipping registry check as non-primary instance
    exit 0
fi
for i in ${NIFI_REGISTRY_HOSTS//,/ }
do
    echo [$(date)] Checking/registering registry ${i} 
    result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi list-reg-clients | grep "${i}")
    rc=$?
    until [ 0 == $rc ]
    do
        "${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi create-reg-client --registryClientName "${i}" --registryClientUrl "http://${i}:18080"
        result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi list-reg-clients | grep "${i}")
        rc=$?
    done
    echo [$(date)] Got registry client: "${result}"
done