#!/bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2023 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

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