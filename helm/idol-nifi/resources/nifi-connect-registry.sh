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

#NIFI_REGISTRY_HOSTS only ever has one host name
echo "[$(date)] Checking/registering registry ${NIFI_REGISTRY_HOSTS}"

REG_URI=http://${NIFI_REGISTRY_HOSTS}:18080/

REG_CLIENTS=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi list-reg-clients -ot json)
REG_CLIENT_ID=$(echo "${REG_CLIENTS}" | jq -r '.registries[0].registry.id // ""')
REG_CLIENT_URI=$(echo "${REG_CLIENTS}" | jq -r '.registries[0].registry.uri // ""')

if [ -z "${REG_CLIENT_ID}" ]; then
    echo "[$(date)] No existing registry client, will create one"
    "${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi create-reg-client -rcn "${NIFI_REGISTRY_HOSTS}" -rcu "${REG_URI}"
    REG_CLIENTS=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi list-reg-clients -ot json)
    REG_CLIENT_ID=$(echo "${REG_CLIENTS}" | jq -r ".registries[0].registry.id")
    REG_CLIENT_URI=$(echo "${REG_CLIENTS}" | jq -r ".registries[0].registry.uri")
elif [ "${REG_CLIENT_URI}" != "${REG_URI}" ]; then
    echo "[$(date)] Existing registry client ${REG_CLIENT_ID} requires URL update: ${REG_CLIENT_URI} -> ${REG_URI}"
    #Updates to the registry client cannot be done via CLI, so use the rest API instead
    REG_CLIENT_API_URL=http://${HOSTNAME}:8080/nifi-api/controller/registry-clients/${REG_CLIENT_ID}
    UPDATE_REG_CLIENT_DEF=$(curl -s "${REG_CLIENT_API_URL}" | jq  ".component.properties.url = \"${REG_URI}\"")
    NEW_REG_CLIENT_DEF=$(curl -X PUT "${REG_CLIENT_API_URL}" -H "Content-Type: application/json" -d "${UPDATE_REG_CLIENT_DEF}")
    REG_CLIENT_ID=$(echo "${NEW_REG_CLIENT_DEF}" | jq -r ".component.id")
    REG_CLIENT_URI=$(echo "${NEW_REG_CLIENT_DEF}" | jq -r ".component.properties.url")
else
    echo "[$(date)] Existing registry client ${REG_CLIENT_ID} has correct URL: ${REG_URI}"
fi

echo "[$(date)] Got registry client: ${REG_CLIENT_ID} (${REG_URI})"
