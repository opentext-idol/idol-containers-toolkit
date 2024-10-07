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
mkdir -p ${logdir}

. "$( dirname "${BASH_SOURCE[0]}" )"/nifi-toolkit-utils.sh

NIFI_REGISTRY_URL=http://${HOSTNAME}:18080

logfile=${logdir}/post-start.log
(
    nifitoolkit_registry_waitForCLI "${NIFI_REGISTRY_URL}"

    for i in $(seq 0 "${NIFI_REGISTRY_BUCKET_COUNT}"); do
        if [  "$i" -eq "${NIFI_REGISTRY_BUCKET_COUNT}" ]; then
            continue
        fi

        FLOWFILES_ENV_NAME=NIFI_REGISTRY_BUCKET_FILES_$i
        BUCKETNAME_ENV_NAME=NIFI_REGISTRY_BUCKET_NAME_$i
        FLOWFILES="${!FLOWFILES_ENV_NAME}"
        BUCKET_NAME="${!BUCKETNAME_ENV_NAME}"

        # Create the bucket
        BUCKETID=
        nifitoolkit_registry_findOrCreateBucket "${NIFI_REGISTRY_URL}" "${BUCKET_NAME}" BUCKETID
        echo "[$(date)] Got bucket ${BUCKET_NAME}: ${BUCKETID}"

        # Import any flows
        for FLOWFILE in ${FLOWFILES//,/ }
        do
            echo "[$(date)] Processing FLOWFILE ${FLOWFILE}"

            if [ ! -f "${FLOWFILE}" ]; then
                echo "[$(date)] FLOWFILE ${FLOWFILE} does not exist"
                echo "[$(date)] Flow import skipped"
                continue
            fi

            FLOWID=
            FLOWVERSION=
            nifitoolkit_registry_importFlow "${NIFI_REGISTRY_URL}" "${BUCKETID}" "${FLOWFILE}" FLOWID FLOWVERSION
            echo "[$(date)] Imported Flow ${FLOWID} (version ${FLOWVERSION})"
        done

    done
) | tee -a ${logfile}
