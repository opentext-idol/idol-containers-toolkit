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

NIFITOOLKITCMD=${NIFI_TOOLKIT_HOME}/bin/cli.sh
NIFI_REGISTRY_URL=http://nifi-registry:18080
BUCKET_NAME="default-bucket"

# The flow file we want to import
FLOWFILE="${IDOL_NIFI_FLOWFILE:-/scripts/flow-basic-idol.json}"

if [ ! -f "${FLOWFILE}" ]; then
    echo "FLOWFILE ${FLOWFILE} does not exist"
    echo "Flow import skipped"
    exit 0
fi

# The name of the flow - extracted from the flow file
FLOW_NAME=$(jq -r .flowContents.name "${FLOWFILE}")

# Check if a process group with the right name already exists in NiFi - done if we find one
echo "Checking for flow ${FLOW_NAME}"
PGLIST=$(${NIFITOOLKITCMD} nifi pg-list)
RC=$?
until [ 0 == ${RC} ];
do
    sleep 5s
    PGLIST=$(${NIFITOOLKITCMD} nifi pg-list)
    RC=$?
done

OUTPUT=$(echo "${PGLIST}" | grep "${FLOW_NAME}")
RC=$?
echo "RC=${RC} OUTPUT=${OUTPUT}"
if [ 0 == ${RC} ]; then
    echo "Found exising flow: ${OUTPUT}"
    echo "Flow import skipped"
    exit 0
fi

# Get NiFi Root ID
#ROOTID=$(${NIFITOOLKITCMD} nifi get-root-id)

# Check if flow exists in the registry
BUCKETID=
until [ -n "${BUCKETID}" ];
do
    BUCKETID=$(${NIFITOOLKITCMD} registry list-buckets -u "${NIFI_REGISTRY_URL}" -ot json | jq ".[] | select(.name==\"${BUCKET_NAME}\")" | jq -r .identifier)
    if [ -z "${BUCKETID}" ];
    then
        sleep 5s
    fi
done
echo "BUCKETID=${BUCKETID}"

FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
RC=$?
until [ 0 == ${RC} ];
do
    sleep 5s
    FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
    RC=$?
done

FLOWID=$(echo ${FLOWS} | jq ".[] | select(.name==\"${FLOW_NAME}\")" | jq -r .identifier)
if [ -z "${FLOWID}" ]; then
    # flow not found - create
    FLOWID=$(${NIFITOOLKITCMD} registry create-flow -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -fn "${FLOW_NAME}")
fi
echo "FLOWID=${FLOWID}"

# Import the flow file as the latest version
FLOWVERSION=$(${NIFITOOLKITCMD} registry import-flow-version -u "${NIFI_REGISTRY_URL}" -f "${FLOWID}" -i "${FLOWFILE}")
echo "FLOWVERSION=${FLOWVERSION}"

# Import the flow as a process group
PROCESSGROUP=$(${NIFITOOLKITCMD} nifi pg-import -b "${BUCKETID}" -f "${FLOWID}" -fv "${FLOWVERSION}" -cto 60000 -rto 60000)
RC=$?
if [ 0 != ${RC} ]; then
    echo "nifi pg-import failed (RC=${RC}). Manual flow import may be required"
    exit 0
fi
echo "PROCESSGROUP=${PROCESSGROUP}"

# Set any parameter values
PARAMCONTEXT=$(${NIFITOOLKITCMD} nifi pg-get-param-context -pgid "${PROCESSGROUP}")
RC=$?
if [ 0 != ${RC} ]; then
    echo "nifi pg-get-param-context failed (RC=${RC}). Manual flow setup may be required"
    # but continue
else
    echo "PARAMCONTEXT=${PARAMCONTEXT}"
    ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "LicenseServerHost" -pv "{{ (index .Values "idol-licenseserver").licenseServerService }}"
    ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "LicenseServerACIPort" -pv "{{ (index .Values "idol-licenseserver").licenseServerPort }}"
    ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IndexHost" -pv "{{ .Values.indexserviceName }}"
    ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IndexACIPort" -pv "{{ .Values.indexserviceACIPort }}"
fi


echo Enabling services 
# Some processors can be slow to start up, so be forgiving
set +e
${NIFITOOLKITCMD} nifi pg-enable-services -pgid "${PROCESSGROUP}" -verbose
RC=$?
if [ 0 != ${RC} ]; then
    echo "nifi pg-enable-services failed (RC=${RC}). Services/processors may not be started."
    # but continue
fi
sleep 30s

echo Starting processors
for i in {1..12} 
do 
    ${NIFITOOLKITCMD} nifi pg-start -pgid "${PROCESSGROUP}" -verbose
    sleep 5s
    NIFISTATUS=$(${NIFITOOLKITCMD} nifi pg-status -pgid "${PROCESSGROUP}" -ot json)
    RC=$?
    if [ 0 != ${RC} ]; then
        sleep 5s
        continue
    fi
    INVALID=$(echo ${NIFISTATUS} | jq .invalidCount)
    STOPPED=$(echo ${NIFISTATUS} | jq .stoppedCount)
    RUNNING=$(echo ${NIFISTATUS} | jq .runningCount)
    echo "Processor status: ${RUNNING} running, ${STOPPED} stopped, ${INVALID} invalid"
    if [ "0" == $((STOPPED+INVALID)) ]; then
        break
    fi
done
${NIFITOOLKITCMD} nifi pg-status -pgid "${PROCESSGROUP}" 
echo "Flow import completed"

