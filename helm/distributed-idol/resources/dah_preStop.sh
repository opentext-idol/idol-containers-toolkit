#! /bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2023-2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{/* 
preStop hook is used in mirror mode to allow child engines a chance 
to run their preStop hooks before the DAH disappears (as they are unable
to tell the difference between scaledown and undeploy).
In non-mirror mode this is a no-op
*/}}
{{- if .Values.setupMirrored }}

. "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"

function waitForLastEngine() {
    local engines=2
    local wait=30
    for i in $(seq $wait)
    do
      engines=$(curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=showstatus" | sed "s@<engine @\n<engine @g" | grep -c "<engine ")
      if [ "$engines" -eq 1 ]; then
        break
      fi
      sleep 1
    done
}

. "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"

logfile=/etc/config/idol/dah_prestop.log
(
  echo "[$(date)] DAH waiting for child engines before shutdown."
  waitForAci localhost "${IDOL_DAH_ACI_PORT}"
  waitForLastEngine
  echo "[$(date)] DAH is shutting down."

) | tee -a "${logfile}

{{- else }}
echo "Nothing to do in non-mirror mode"
{{- end }}
