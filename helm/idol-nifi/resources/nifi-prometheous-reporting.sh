#!/bin/bash

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


echo "[$(date)] Checking/registering prometheous reporting task"
result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi get-reporting-tasks | grep "PrometheusReportingTask")
rc=$?
until [ 0 == $rc ]
do
    "${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi create-reporting-task --input /scripts/prometheous-reporting-task.json
    result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi get-reporting-tasks | grep "PrometheusReportingTask")
    rc=$?
done
echo "[$(date)] Got prometheous reporting task: ${result}"

taskid=$(echo "${result}" | grep -Eoh "[0-9a-fA-F\-]{36}")
echo "[$(date)] Starting prometheous reporting task: ${taskid}"

"${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi start-reporting-tasks -rt "${taskid}"
result=$("${NIFI_TOOLKIT_HOME}/bin/cli.sh" nifi get-reporting-tasks | grep "PrometheusReportingTask")
echo "[$(date)] Got prometheous reporting task: ${result}"
