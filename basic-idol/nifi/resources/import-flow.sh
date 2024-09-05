#!/bin/bash

set -x -o allexport

if [ -z "${JAVA_HOME}" ]
then
    JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 | grep java.home | cut -d = -f 2 | xargs)
    export JAVA_HOME="$JAVA_HOME"
    echo ["$(date)"] Using auto-detected JAVA_HOME: "$JAVA_HOME"
fi

NIFI_API_URL="http://idol-nifi:8081/nifi-api"
NIFITOOLKITCMD=${NIFI_TOOLKIT_HOME}/bin/cli.sh
PROCESS_GROUP_NAME="Basic IDOL"

# The flow file we want to import
FLOWFILE="${IDOL_NIFI_FLOWFILE:-/opt/nifi/scripts/flow-basic-idol.json}"

if [ ! -f "${FLOWFILE}" ]; then
    echo [$(date)] "FLOWFILE ${FLOWFILE} does not exist"
    echo [$(date)] "Flow import skipped"
    exit 0
fi

# Check if a process group with the right name already exists in NiFi - done if we find one
echo [$(date)] "Checking for flow ${PROCESS_GROUP_NAME}"
PGLIST=$(${NIFITOOLKITCMD} nifi pg-list)
RC=$?
until [ 0 == ${RC} ];
do
    sleep 5s
    PGLIST=$(${NIFITOOLKITCMD} nifi pg-list)
    RC=$?
done

OUTPUT=$(echo "${PGLIST}" | grep "${PROCESS_GROUP_NAME}")
RC=$?
echo [$(date)] "RC=${RC} OUTPUT=${OUTPUT}"
if [ 0 == ${RC} ]; then
    echo [$(date)]"Found exising flow: ${OUTPUT}"
    echo [$(date)]"Flow import skipped"
    exit 0
fi

curl -X POST "${NIFI_API_URL}/process-groups/root/process-groups/upload" -F "file=@${FLOWFILE}" -F "groupName=${PROCESS_GROUP_NAME}" -F "positionX=0" -F "positionY=0" -F clientId=idol-nifi-docker-compose
RC=$?
if [ 0 != ${RC} ]; then
    echo [$(date)] "Flow file upload failed (RC=${RC}). Manual flow import may be required"
    exit 0
fi

ROOT_PROCESS_GROUP=$(curl "${NIFI_API_URL}/process-groups/root" | jq -r '.id')
BASIC_IDOL_PROCESS_GROUP_ID=$(curl "${NIFI_API_URL}/process-groups/${ROOT_PROCESS_GROUP}/process-groups" | jq -r ".processGroups[] | select(.component.name == \"${PROCESS_GROUP_NAME}\") | .id")
echo [$(date)] "BASIC_IDOL_PROCESS_GROUP_ID=${BASIC_IDOL_PROCESS_GROUP_ID}"

echo [$(date)] Enabling services
# Some processors can be slow to start up, so be forgiving
set +e
${NIFITOOLKITCMD} nifi pg-enable-services -pgid "${BASIC_IDOL_PROCESS_GROUP_ID}" -verbose
RC=$?
if [ 0 != ${RC} ]; then
    echo [$(date)] "nifi pg-enable-services failed (RC=${RC}). Services/processors may not be started."
    # but continue
fi
INVALID=$(echo ${NIFISTATUS} | jq .enabledCount)
STOPPED=$(echo ${NIFISTATUS} | jq .disabledCount)
RUNNING=$(echo ${NIFISTATUS} | jq .runningCount)
sleep 30s

echo [$(date)] Starting processors
for i in {1..12}
do
    ${NIFITOOLKITCMD} nifi pg-start -pgid "${BASIC_IDOL_PROCESS_GROUP_ID}" -verbose
    sleep 5s
    NIFISTATUS=$(${NIFITOOLKITCMD} nifi pg-status -pgid "${BASIC_IDOL_PROCESS_GROUP_ID}" -ot json)
    RC=$?
    if [ 0 != ${RC} ]; then
        sleep 5s
        continue
    fi
    INVALID=$(echo ${NIFISTATUS} | jq .invalidCount)
    STOPPED=$(echo ${NIFISTATUS} | jq .stoppedCount)
    RUNNING=$(echo ${NIFISTATUS} | jq .runningCount)
    echo [$(date)] "Processor status: ${RUNNING} running, ${STOPPED} stopped, ${INVALID} invalid"
    if [ "0" == $((STOPPED+INVALID)) ]; then
        break
    fi
done
${NIFITOOLKITCMD} nifi pg-status -pgid "${BASIC_IDOL_PROCESS_GROUP_ID}"
echo [$(date)] "Flow import completed"