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
    echo "[$(date)] No NiFi Registry hosts"
    echo "[$(date)] Flow import skipped"
    exit 0
fi

. "$( dirname "${BASH_SOURCE[0]}" )/nifi-toolkit-utils.sh"

NIFI_REGISTRY_URL=http://${NIFI_REGISTRY_HOSTS}:18080
NEW_PROCESS_GROUP_IDS=()

nifitoolkit_registry_waitForCLI "${NIFI_REGISTRY_URL}"

for i in $(seq 0 "${IDOL_NIFI_FLOW_COUNT}");
do
    if [  "$i" -eq "${IDOL_NIFI_FLOW_COUNT}" ]; then
        continue
    fi

    FLOWFILE_ENV_NAME=IDOL_NIFI_FLOW_FILE_$i
    FLOWNAME_ENV_NAME=IDOL_NIFI_FLOW_NAME_$i
    FLOWVERSION_ENV_NAME=IDOL_NIFI_FLOW_VERSION_$i
    BUCKETNAME_ENV_NAME=IDOL_NIFI_FLOW_BUCKET_$i
    FLOWIMPORT_ENV_NAME=IDOL_NIFI_FLOW_IMPORT_$i

    FLOWFILE="${!FLOWFILE_ENV_NAME}"
    FLOWNAME="${!FLOWNAME_ENV_NAME}"
    FLOWVERSION="${!FLOWVERSION_ENV_NAME}"
    BUCKET_NAME="${!BUCKETNAME_ENV_NAME}"
    FLOWIMPORT="${!FLOWIMPORT_ENV_NAME}"

    if [ -z "${FLOWFILE}" ]; then
        echo "[$(date)] Processing Flow ${FLOWNAME} (bucket: ${BUCKET_NAME}, version: ${FLOWVERSION})"
    elif [ ! -f "${FLOWFILE}" ]; then
        echo "[$(date)] FLOWFILE ${FLOWFILE} does not exist"
        echo "[$(date)] Flow import skipped"
        continue
    else
        echo "[$(date)] Processing FLOWFILE ${FLOWFILE} (bucket: ${BUCKET_NAME})"

        # Extracted the name of the flow from the flow file
        FLOWNAME=$(jq -r .flowContents.name "${FLOWFILE}")
    fi

    # Check if a process group with the right name already exists in NiFi - done if we find one
    echo "[$(date)] Checking for flow ${FLOWNAME}"
    EXISTINGPGID=
    EXISTINGFLOWID=
    EXISTINGFLOWVERSION=
    EXISTINGFLOWSTATE=
    nifitoolkit_nifi_findProcessGroup "${FLOWNAME}" EXISTINGPGID EXISTINGFLOWID EXISTINGFLOWVERSION EXISTINGFLOWSTATE

    if [ -z "${EXISTINGPGID}" ]; then
        echo "[$(date)] No exising flow found"
    else
        echo "[$(date)] Found exising flow: ${EXISTINGPGID} (FlowId: ${EXISTINGFLOWID}, Version: ${EXISTINGFLOWVERSION}, State: ${EXISTINGFLOWSTATE})"
        
        if [ -z "${EXISTINGFLOWID}" ]; then
            echo "[$(date)] Existing flow is not versioned "
            echo "[$(date)] Flow import skipped"
            continue
        fi
    fi

    BUCKETID=
    if [ -z "${FLOWFILE}" ]; then
        nifitoolkit_registry_findBucket "${NIFI_REGISTRY_URL}" "${BUCKET_NAME}" BUCKETID
        if [ -z "${BUCKETID}" ]; then
            echo "[$(date)] Source bucket '${BUCKET_NAME}' not found"
            echo "[$(date)] Flow import skipped"
            continue
        fi
    else
        nifitoolkit_registry_findOrCreateBucket "${NIFI_REGISTRY_URL}" "${BUCKET_NAME}" BUCKETID
    fi
    echo "[$(date)] Got bucket ${BUCKET_NAME}": "${BUCKETID}"

    FLOWID=
    if [ -z "${FLOWFILE}" ]; then
        FLOWVERSIONS=
        nifitoolkit_registry_findFlow "${NIFI_REGISTRY_URL}" "${BUCKETID}" "${FLOWNAME}" FLOWID FLOWVERSIONS

        if [ -z "${FLOWID}" ]; then
            echo "[$(date)] Flow ${FLOWNAME} not found, flow import skipped"
            continue
        fi

        if [ -z "${FLOWVERSION}" ]; then
            FLOWVERSION=${FLOWVERSIONS##*,}
            echo "[$(date)] Using latest version: ${FLOWVERSION}"
        fi
        #TODO: Verify requested version exists?
    else
        FLOWVERSION=
        nifitoolkit_registry_importFlow "${NIFI_REGISTRY_URL}" "${BUCKETID}" "${FLOWFILE}" FLOWID FLOWVERSION
        echo "[$(date)] Imported Flow ${FLOWID} (version ${FLOWVERSION})"
    fi
    
    if [ -n "${EXISTINGFLOWID}" ] && [ "${EXISTINGFLOWID}" != "${FLOWID}" ]; then
        echo "[$(date)] Flow Id mismatch: Process Group: ${EXISTINGFLOWID}, Registry: ${FLOWID}"
        echo "[$(date)] Flow import skipped"
        continue
    fi

    if [ "true" != "${FLOWIMPORT}" ]; then
        echo "[$(date)] Not importing flow as process group due to configuration"
        continue
    fi

    if [ -n "${EXISTINGFLOWID}" ]; then
        
        if [ "${EXISTINGFLOWVERSION}" == "${FLOWVERSION}" ]; then
            echo "[$(date)] Not importing flow as existing process group is the desired version"
            continue
        fi

        echo "[$(date)] Existing process group version needs changing: ${EXISTINGFLOWVERSION} -> ${FLOWVERSION}"
        nifitoolkit_nifi_changeProcessGroupVersion "${EXISTINGPGID}" "${FLOWVERSION}"
    else
        # Import the flow as a process group
        PROCESSGROUP=$(${NIFITOOLKITCMD} nifi pg-import -b "${BUCKETID}" -f "${FLOWID}" -fv "${FLOWVERSION}" -cto 60000 -rto 60000)
        RC=$?
        if [ 0 != ${RC} ]; then
            echo "[$(date)] nifi pg-import failed (RC=${RC}). Manual flow import may be required"
            continue
        fi
        echo "[$(date)] PROCESSGROUP=${PROCESSGROUP}"

        # Set any parameter values
        PARAMCONTEXT=$(${NIFITOOLKITCMD} nifi pg-get-param-context -pgid "${PROCESSGROUP}")
        RC=$?
        if [ 0 != ${RC} ]; then
            echo "[$(date)] nifi pg-get-param-context failed (RC=${RC}). Manual flow setup may be required"
            # but continue
        else
            echo "[$(date)] PARAMCONTEXT=${PARAMCONTEXT}"
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "LicenseServerHost" -pv "{{ (index .Values "idol-licenseserver").licenseServerService }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "LicenseServerACIPort" -pv "{{ (index .Values "idol-licenseserver").licenseServerPort }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "IndexHost" -pv "{{ .Values.indexserviceName }}"
#{{- if .Values.postgresql.enabled }}
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "PostgreSQLServer" -pv "{{ .Release.Name }}-postgresql-pgpool"
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "PostgreSQLDatabase" -pv "{{ .Values.postgresql.postgresql.database }}"
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "PostgreSQLUser" -pv "{{ .Values.postgresql.postgresql.username }}" -ps true
            ${NIFITOOLKITCMD} nifi set-param -pcid "${PARAMCONTEXT}" -pn "PostgreSQLPassword" -pv "{{ .Values.postgresql.postgresql.password }}" -ps true
#{{- end }}
        fi

        echo "[$(date)] FLOWFILE ${FLOWFILE} imported to ProcessGroup: ${PROCESSGROUP}."
        NEW_PROCESS_GROUP_IDS+=("${PROCESSGROUP}")
    fi
done

for PROCESS_GROUP_ID in "${NEW_PROCESS_GROUP_IDS[@]}"
do
    echo "[$(date)] Starting services in ProcessGroup: ${PROCESS_GROUP_ID}."

    echo "[$(date)] Enabling services"
    # Some processors can be slow to start up, so be forgiving
    set +e
    ${NIFITOOLKITCMD} nifi pg-enable-services -pgid "${PROCESS_GROUP_ID}" -verbose
    RC=$?
    if [ 0 != ${RC} ]; then
        echo "[$(date)] nifi pg-enable-services failed (RC=${RC}). Services/processors may not be started."
        # but continue
    fi
done

if [ 0 != ${#NEW_PROCESS_GROUP_IDS[@]} ]; then
    echo "[$(date)] Waiting after service start."
    sleep 30s
fi

for PROCESS_GROUP_ID in "${NEW_PROCESS_GROUP_IDS[@]}"
do
    echo "[$(date)] Starting processors in ProcessGroup: ${PROCESS_GROUP_ID}."
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
        INVALID=$(echo "${NIFISTATUS}" | jq .invalidCount)
        STOPPED=$(echo "${NIFISTATUS}" | jq .stoppedCount)
        RUNNING=$(echo "${NIFISTATUS}" | jq .runningCount)
        echo "[$(date)] Processor status: ${RUNNING} running, ${STOPPED} stopped, ${INVALID} invalid"
        if [ "0" == "$((STOPPED+INVALID))" ]; then
            break
        fi
    done
    ${NIFITOOLKITCMD} nifi pg-status -pgid "${PROCESS_GROUP_ID}" 
done

echo "[$(date)] Flow import completed"

