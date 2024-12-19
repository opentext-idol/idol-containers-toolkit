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

# Creates required databases for QMS AgentStore

source /content/startup_utils.sh

waitForAci "localhost:{{ .Values.answerbankAgentstore.aciPort | int }}"
DBS="agent profile activated deactivated DataAdminDeleted"

for DB in ${DBS};
do
    curl -S -s --noproxy "*" --insecure -o /dev/null "${HTTP_SCHEME}://localhost:{{ .Values.answerbankAgentstore.indexPort | int }}/DRECREATEDBASE?&DREDBNAME=${DB}"
done
