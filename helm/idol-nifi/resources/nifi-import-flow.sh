#!/bin/bash
set -x -o allexport

NIFITOOLKITCMD=${NIFI_TOOLKIT_HOME}/bin/cli.sh
NIFI_REGISTRY_URL=http://nifi-registry:18080
BUCKET_NAME="default-bucket"

# The flow file we want to import
FLOWFILE="${IDOL_NIFI_FLOWFILE:-/scripts/flow-basic-idol.json}"
# The name of the flow - extracted from the flow file
FLOW_NAME=$(jq -r .flowContents.name "${FLOWFILE}")

# Check if a process group with the right name already exists in NiFi - done if we find one
echo "Checking for flow ${FLOW_NAME}"
OUTPUT=$(${NIFITOOLKITCMD} nifi pg-list | grep "${FLOW_NAME}")
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
echo "PROCESSGROUP=${PROCESSGROUP}"

# Set any parameter values
PARAMCONTEXT=$(${NIFITOOLKITCMD} nifi pg-get-param-context -pgid "${PROCESSGROUP}")
echo "PARAMCONTEXT=${PARAMCONTEXT}"
#${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IDOL Host" -pv "${IDOL_HOST}"
#${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IDOL LicenseServer Host" -pv "${IDOL_LICENSESERVER_HOST}"
#${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IDOL ACI Port" -pv "9100"


echo Enabling services and starting processors...
# Some processors can be slow to start up, so be forgiving
set +e
${NIFITOOLKITCMD} nifi pg-enable-services -pgid "${PROCESSGROUP}" -verbose
sleep 30s
${NIFITOOLKITCMD} nifi pg-start -pgid "${PROCESSGROUP}" -verbose