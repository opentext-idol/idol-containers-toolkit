#! /bin/bash
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