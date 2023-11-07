#! /bin/bash

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

logdir=/opt/nifi-registry/nifi-registry-current/logs
logfile=${logdir}/post-start.log
bucketname=default-bucket
mkdir -p ${logdir}
echo [$(date)] Checking registry for "${bucketname}" | tee -a ${logfile}
result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" registry list-buckets -u "http://${HOSTNAME}:18080" | grep "${bucketname}")
rc=$?
until [ 0 == $rc ]
do
    "${NIFI_TOOLKIT_HOME}/bin/cli.sh" registry create-bucket --bucketName "${bucketname}" -u "http://${HOSTNAME}:18080"
    result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" registry list-buckets -u "http://${HOSTNAME}:18080" | grep "${bucketname}")
    rc=$?
done
echo [$(date)] Got bucket "${bucketname}": "${result}" | tee -a ${logfile}