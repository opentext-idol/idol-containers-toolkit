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

NIFITOOLKITCMD=${NIFI_TOOLKIT_HOME}/bin/cli.sh

nifitoolkit_nifi_waitForCLI() {
    timeout 10m bash -c "until ${NIFITOOLKITCMD} nifi current-user >/dev/null; do echo [\$(date)] Waiting for NiFi CLI...; sleep 5; done"
}

nifitoolkit_nifi_findProcessGroup() {
    local PGNAME=$1
    local OUT_PGID=$2
    local OUT_EXISTINGFLOWID=$3
    local OUT_EXISTINGFLOWVERSION=$4
    local OUT_EXISTINGFLOWSTATE=$5

    local PGLIST=
    PGLIST=$(${NIFITOOLKITCMD} nifi pg-list -ot json)
    RC=$?
    until [ 0 == ${RC} ];
    do
        sleep 5s
        PGLIST=$(${NIFITOOLKITCMD} nifi pg-list -ot json)
        RC=$?
    done

    PGID=$(echo "${PGLIST}" | jq ".[] | select(.name==\"${PGNAME}\")" | jq -r .id)
    EXISTINGFLOWID=$(echo "${PGLIST}" | jq ".[] | select(.name==\"${PGNAME}\")" | jq -r .versionControlInformation.flowId)
    EXISTINGFLOWVERSION=$(echo "${PGLIST}" | jq ".[] | select(.name==\"${PGNAME}\")" | jq -r .versionControlInformation.version)
    EXISTINGFLOWSTATE=$(echo "${PGLIST}" | jq ".[] | select(.name==\"${PGNAME}\")" | jq -r .versionControlInformation.state)

    declare -g "$OUT_PGID=${PGID}"
    declare -g "$OUT_EXISTINGFLOWID=${EXISTINGFLOWID}"
    declare -g "$OUT_EXISTINGFLOWVERSION=${EXISTINGFLOWVERSION}"
    declare -g "$OUT_EXISTINGFLOWSTATE=${EXISTINGFLOWSTATE}"
}

nifitoolkit_nifi_getClusterNodeCount() {
    local OUT_NODECOUNT=$1

    echo "[$(date)] Getting NiFi cluster summary"
    local NODECOUNT=
    NODECOUNT=$(${NIFITOOLKITCMD} nifi cluster-summary -ot json | jq -r .clusterSummary.totalNodeCount)
    RC=$?
    # Wait to receieve a valid cluster node summary. There should be at least 1 node (this one).
    until [ 0 == ${RC} ]&& [ -n "${NODECOUNT}" ] && [ "${NODECOUNT}" -gt 0 ];
    do
        echo "[$(date)] Waiting for NiFi cluster summary..."
        sleep 5s
        NODECOUNT=$(${NIFITOOLKITCMD} nifi cluster-summary -ot json | jq -r .clusterSummary.totalNodeCount)
        RC=$?
    done

    echo "[$(date)] ${NODECOUNT} node(s) in NiFi cluster"
    declare -g "$OUT_NODECOUNT=${NODECOUNT}"
}

nifitoolkit_nifi_changeProcessGroupVersion() {
    local PGID=$1
    local VERSION=$2
    local RESULT=
    RESULT=$(${NIFITOOLKITCMD} nifi pg-change-version -pgid "${PGID}" -fv "${VERSION}" -ot json)
    RC=$?
    if [ 0 == ${RC} ]; then
        echo "[$(date)] Changed the version of PG ${PGID} to ${VERSION}"
    else
        echo "[$(date)] Failed to change the version of PG ${PGID} to ${VERSION}: ${RESULT}"
    fi
}


#Registry utilities
nifitoolkit_registry_waitForCLI() {
    local NIFI_REGISTRY_URL=$1
    timeout 10m bash -c "until ${NIFITOOLKITCMD} registry current-user -u ${NIFI_REGISTRY_URL} >/dev/null; do echo [\$(date)] Waiting for NiFi Registry CLI...; sleep 5; done"
}


nifitoolkit_registry_findBucket() {
    local NIFI_REGISTRY_URL=$1
    local BUCKET_NAME=$2
    local OUT_BUCKETID=$3

    BUCKETID=$(${NIFITOOLKITCMD} registry list-buckets -u "${NIFI_REGISTRY_URL}" -ot json | jq ".[] | select(.name==\"${BUCKET_NAME}\")" | jq -r .identifier)

    declare -g "$OUT_BUCKETID=${BUCKETID}"
}

nifitoolkit_registry_findOrCreateBucket() {
    local NIFI_REGISTRY_URL=$1
    local BUCKET_NAME=$2
    local OUT_BUCKETID=$3

    local BUCKETID=
    until [ -n "${BUCKETID}" ];
    do
        echo "[$(date)] Checking registry for ${BUCKET_NAME}"
        BUCKETID=$(${NIFITOOLKITCMD} registry list-buckets -u "${NIFI_REGISTRY_URL}" -ot json | jq ".[] | select(.name==\"${BUCKET_NAME}\")" | jq -r .identifier)
        if [ -z "${BUCKETID}" ]; then
            echo "[$(date)] Bucket not found, creating registry bucket ${BUCKET_NAME}"
            BUCKETID=$(${NIFITOOLKITCMD} registry create-bucket -u "${NIFI_REGISTRY_URL}" --bucketName "${BUCKET_NAME}" -ot json | jq -r .identifier)
        fi
    done
    echo "[$(date)] Got bucket ${BUCKET_NAME}": "${BUCKETID}"
    declare -g "$OUT_BUCKETID=${BUCKETID}"
}

nifitoolkit_registry_importFlow (){
    local NIFI_REGISTRY_URL=$1
    local BUCKETID=$2
    local FLOW_FILE=$3
    local OUT_FLOWID=$4
    local OUT_FLOWVERSION=$5

    # The name of the flow - extracted from the flow file
    local FLOW_NAME=
    FLOW_NAME=$(jq -r .flowContents.name "${FLOW_FILE}")
    local FLOWID=
    local FLOWVERSION=
    until [ -n "${FLOWID}" ];
    do
        local FLOWS=
        FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
        RC=$?
        until [ 0 == ${RC} ];
        do
            sleep 5s
            FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
            RC=$?
        done

        FLOWID=$(echo "${FLOWS}" | jq ".[] | select(.name==\"${FLOW_NAME}\")" | jq -r .identifier)
        if [ -z "${FLOWID}" ]; then
            # flow not found - create
            FLOWID=$(${NIFITOOLKITCMD} registry create-flow -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -fn "${FLOW_NAME}")
        else
            local LATESTFLOWVERSION=
            LATESTFLOWVERSION=$(${NIFITOOLKITCMD} registry list-flow-versions -u "${NIFI_REGISTRY_URL}" --flowIdentifier "${FLOWID}" -ot json | jq .[-1].version)
            if [ -n "${LATESTFLOWVERSION}" ]; then
                #Sort, and remove fields added by the import-flow-version process
                local JQ=(jq -S 'del(.snapshotMetadata,.latest) | del(..|nulls) | walk(if type=="array" then .|=sort_by(.name?) else . end)')

                echo "[$(date)] Comparing flow ${FLOW_NAME} to latest version (${LATESTFLOWVERSION}) in registry..."

                diff <(${NIFITOOLKITCMD} registry export-flow-version -u "${NIFI_REGISTRY_URL}" --flowIdentifier "${FLOWID}" --flowVersion "${LATESTFLOWVERSION}" -ot json | "${JQ[@]}" ) \
                     <("${JQ[@]}" "${FLOW_FILE}")
                RC=$?
                if [ 0 == ${RC} ]; then
                    echo "[$(date)] Flow ${FLOW_NAME} matches latest version (${LATESTFLOWVERSION}) in registry, will not create a new version"
                    FLOWVERSION=${LATESTFLOWVERSION}
                else
                    echo "[$(date)] Flow ${FLOW_NAME} differs from latest version in registry, will create a new version"
                fi
            fi
        fi
    done
    echo "[$(date)] FLOWID=${FLOWID}"

    if [ -z "${FLOWVERSION}" ]; then
        # Import the flow file as the latest version
        FLOWVERSION=$(${NIFITOOLKITCMD} registry import-flow-version -u "${NIFI_REGISTRY_URL}" -f "${FLOWID}" -i "${FLOW_FILE}")
        echo "[$(date)] FLOWVERSION=${FLOWVERSION}"
    fi

    declare -g "$OUT_FLOWID=${FLOWID}"
    declare -g "$OUT_FLOWVERSION=${FLOWVERSION}"
}

nifitoolkit_registry_findFlow (){
    local NIFI_REGISTRY_URL=$1
    local BUCKETID=$2
    local FLOW_NAME=$3
    local OUT_FLOWID=$4
    local OUT_FLOWVERSIONS=$5

    local FLOWS=
    FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
    RC=$?
    until [ 0 == ${RC} ];
    do
        sleep 5s
        FLOWS=$(${NIFITOOLKITCMD} registry list-flows -u "${NIFI_REGISTRY_URL}" --bucketIdentifier "${BUCKETID}" -ot json)
        RC=$?
    done

    local FLOWID=
    FLOWID=$(echo "${FLOWS}" | jq ".[] | select(.name==\"${FLOW_NAME}\")" | jq -r .identifier)
    if [ -z "${FLOWID}" ]; then
        # flow not found
        return 1
    fi
    local FLOWVERSIONS=
    FLOWVERSIONS=$(${NIFITOOLKITCMD} registry list-flow-versions -u "${NIFI_REGISTRY_URL}" --flowIdentifier "${FLOWID}" -ot json | jq -r "[.[].version] | @csv")

    echo "[$(date)] FLOWID=${FLOWID}, Versions: ${FLOWVERSIONS}"

    declare -g "$OUT_FLOWID=${FLOWID}"
    declare -g "$OUT_FLOWVERSIONS=${FLOWVERSIONS}"
}

nifitoolkit_configure_threads(){
    local THREADS=$1
    local CONTROLLER_CFG=/opt/nifi/nifi-current/conf/update-controller-configuration.json
    local CONFIGURATION=
    CONFIGURATION=$(${NIFITOOLKITCMD} nifi get-controller-configuration)
    RC=$?
    until [ 0 == ${RC} ];
    do
        sleep 5s
        CONFIGURATION=$(${NIFITOOLKITCMD} nifi get-controller-configuration)
        RC=$?
    done
    echo "${CONFIGURATION}" | jq ".component.maxTimerDrivenThreadCount=${THREADS}" > ${CONTROLLER_CFG}
    ${NIFITOOLKITCMD} nifi update-controller-configuration --input "${CONTROLLER_CFG}"
    echo "[$(date)] Set maxTimerDrivenThreadCount=${THREADS}"
}
