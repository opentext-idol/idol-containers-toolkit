#! /usr/bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

source /content/startup_utils.sh

ACI_PORT={{ .Values.passageextractorAgentstore.aciPort }}
INDEX_PORT={{ .Values.passageextractorAgentstore.indexPort }}

# Creates required databases
function createDbs {
    local DBS="companies people places teams organizations languages elements organisms"
    for DB in ${DBS}
    do
        curl -S -s --noproxy "*" -o /dev/null --insecure "${HTTP_SCHEME}://localhost:${INDEX_PORT}/DRECREATEDBASE?&DREDBNAME=${DB}"
    done
}

# Indexes idx
function indexIdx {
    for i in idx/*.idx.gz
    do
        if [ ! -e "${i}.indexed" ]
        then
            echo "Indexing ${i}"
            curl -S -s --noproxy "*" --insecure -o "${i}.indexed" "${HTTP_SCHEME}://localhost:${INDEX_PORT}/DREADD?/content/${i}"
        fi
    done
}

waitForAci "localhost:${ACI_PORT}"
createDbs
indexIdx
