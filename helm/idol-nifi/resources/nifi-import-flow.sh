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

if [ -z "${NIFI_REGISTRY_HOSTS}" ]; then
    echo [$(date)] "No NiFi Registry hosts"
    echo [$(date)] "Flow import skipped"
    exit 0
fi

NIFITOOLKITCMD=${NIFI_TOOLKIT_HOME}/bin/cli.sh
NIFI_REGISTRY_URL=http://${NIFI_REGISTRY_HOSTS}:18080
PROCESS_GROUP_IDS=()

for i in $(seq 0 ${IDOL_NIFI_FLOW_COUNT});
do
    if [  $i -eq ${IDOL_NIFI_FLOW_COUNT} ]; then
        continue
    fi

    FLOWFILE_ENV_NAME=IDOL_NIFI_FLOW_FILE_$i
    BUCKETNAME_ENV_NAME=IDOL_NIFI_FLOW_BUCKET_$i
    FLOWIMPORT_ENV_NAME=IDOL_NIFI_FLOW_IMPORT_$i

    FLOWFILE="${!FLOWFILE_ENV_NAME}"
    BUCKET_NAME="${!BUCKETNAME_ENV_NAME}"
    FLOWIMPORT="${!FLOWIMPORT_ENV_NAME}"

    if [  -z "${FLOWFILE}" ]; then
        continue
    fi

    if [ ! -f "${FLOWFILE}" ]; then
        echo [$(date)] "FLOWFILE ${FLOWFILE} does not exist"
        echo [$(date)] "Flow import skipped"
    else
        echo [$(date)] "Processing FLOWFILE ${FLOWFILE} (bucket: ${BUCKET_NAME})"

        # The name of the flow - extracted from the flow file
        FLOW_NAME=$(jq -r .flowContents.name "${FLOWFILE}")

        # Check if a process group with the right name already exists in NiFi - done if we find one
        echo [$(date)] "Checking for flow ${FLOW_NAME}"
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
        echo [$(date)] "RC=${RC} OUTPUT=${OUTPUT}"
        if [ 0 == ${RC} ]; then
            echo [$(date)]"Found exising flow: ${OUTPUT}"
            echo [$(date)]"Flow import skipped"
            continue
        fi

        # Get NiFi Root ID
        #ROOTID=$(${NIFITOOLKITCMD} nifi get-root-id)

        # Check if flow exists in the registry
        BUCKETID=
        until [ -n "${BUCKETID}" ];
        do
            echo [$(date)] Checking registry for "${BUCKET_NAME}"
            BUCKETID=$(${NIFITOOLKITCMD} registry list-buckets -u "${NIFI_REGISTRY_URL}" -ot json | jq ".[] | select(.name==\"${BUCKET_NAME}\")" | jq -r .identifier)

            if [ -z "${BUCKETID}" ]; then
            echo [$(date)] Bucket not found, creating registry bucket "${BUCKET_NAME}"
                BUCKETID=$(${NIFITOOLKITCMD} registry create-bucket -u "${NIFI_REGISTRY_URL}" --bucketName "${BUCKET_NAME}" -ot json | jq -r .identifier)
            fi
        done
        echo [$(date)] "BUCKETID=${BUCKETID}"

        FLOWID=
        FLOWVERSION=
        until [ -n "${FLOWID}" ];
        do
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
            else
                LATESTFLOWVERSION=$(${NIFITOOLKITCMD} registry list-flow-versions -u "${NIFI_REGISTRY_URL}" --flowIdentifier "${FLOWID}" -ot json | jq .[-1].version)
                if [ -n "${LATESTFLOWVERSION}" ]; then
                    #Sort, and remove fields added by the import-flow-version process
                    JQ=jq -S "del(.snapshotMetadata, .latest, ..|nulls)"

                    diff <(${NIFITOOLKITCMD} registry export-flow-version -u "${NIFI_REGISTRY_URL}" --flowIdentifier "${FLOWID}" --flowVersion "${LATESTFLOWVERSION}" -ot json | ${JQ} ) \
                         <(${JQ} ${FLOWFILE}) &>/dev/null
                    RC=$?
                    if [ 0 == ${RC} ]; then
                        echo [$(date)] "Flow ${FLOW_NAME} matches latest version (${LATESTFLOWVERSION}) in registry, will not create a new version"
                        FLOWVERSION=${LATESTFLOWVERSION}
                    else
                        echo [$(date)] "Flow ${FLOW_NAME} differs from latest version in registry, will create a new version"
                    fi
                fi
            fi
        done
        echo [$(date)] "FLOWID=${FLOWID}"

        if [ -z "${FLOWVERSION}" ]; then
            # Import the flow file as the latest version
            FLOWVERSION=$(${NIFITOOLKITCMD} registry import-flow-version -u "${NIFI_REGISTRY_URL}" -f "${FLOWID}" -i "${FLOWFILE}")
            echo [$(date)] "FLOWVERSION=${FLOWVERSION}"
        fi

        if [ "true" != "${FLOWIMPORT}" ]; then
            echo [$(date)] "Not importing flow as process group due to configuration"
            continue
        fi

        # Import the flow as a process group
        PROCESSGROUP=$(${NIFITOOLKITCMD} nifi pg-import -b "${BUCKETID}" -f "${FLOWID}" -fv "${FLOWVERSION}" -cto 60000 -rto 60000)
        RC=$?
        if [ 0 != ${RC} ]; then
            echo [$(date)] "nifi pg-import failed (RC=${RC}). Manual flow import may be required"
            continue
        fi
        echo [$(date)] "PROCESSGROUP=${PROCESSGROUP}"

        # Set any parameter values
        PARAMCONTEXT=$(${NIFITOOLKITCMD} nifi pg-get-param-context -pgid "${PROCESSGROUP}")
        RC=$?
        if [ 0 != ${RC} ]; then
            echo [$(date)] "nifi pg-get-param-context failed (RC=${RC}). Manual flow setup may be required"
            # but continue
        else
            echo [$(date)] "PARAMCONTEXT=${PARAMCONTEXT}"
            ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "LicenseServerHost" -pv "{{ (index .Values "idol-licenseserver").licenseServerService }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "LicenseServerACIPort" -pv "{{ (index .Values "idol-licenseserver").licenseServerPort }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IndexHost" -pv "{{ .Values.indexserviceName }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid ${PARAMCONTEXT} -pn "IndexACIPort" -pv "{{ .Values.indexserviceACIPort }}"
        fi

        echo [$(date)] "FLOWFILE ${FLOWFILE} imported to ProcessGroup: ${PROCESSGROUP}."
        PROCESS_GROUP_IDS+=(${PROCESSGROUP})
    fi
done

for PROCESS_GROUP_ID in "${PROCESS_GROUP_IDS[@]}"
do
    echo [$(date)] "Starting services in ProcessGroup: ${PROCESS_GROUP_ID}."

    echo [$(date)] Enabling services 
    # Some processors can be slow to start up, so be forgiving
    set +e
    ${NIFITOOLKITCMD} nifi pg-enable-services -pgid "${PROCESS_GROUP_ID}" -verbose
    RC=$?
    if [ 0 != ${RC} ]; then
        echo [$(date)] "nifi pg-enable-services failed (RC=${RC}). Services/processors may not be started."
        # but continue
    fi
done

if [ ${#PROCESS_GROUP_IDS[@]} ]; then
    echo [$(date)] "Waiting after service start."
    sleep 30s
fi

for PROCESS_GROUP_ID in "${PROCESS_GROUP_IDS[@]}"
do
    echo [$(date)] "Starting processors in ProcessGroup: ${PROCESS_GROUP_ID}."
    for i in {1..12} 
    do 
        ${NIFITOOLKITCMD} nifi pg-start -pgid "${PROCESS_GROUP_ID}" -verbose
        sleep 5s
        NIFISTATUS=$(${NIFITOOLKITCMD} nifi pg-status -pgid "${PROCESS_GROUP_ID}" -ot json)
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
    ${NIFITOOLKITCMD} nifi pg-status -pgid "${PROCESS_GROUP_ID}" 
done

echo [$(date)] "Flow import completed"

