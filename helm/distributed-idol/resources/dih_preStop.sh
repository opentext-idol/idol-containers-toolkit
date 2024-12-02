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
to run their preStop hooks before the DIH disappears (as they are unable
to tell the difference between scaledown and undeploy).
In non-mirror mode this is a no-op
*/}}
{{- if .Values.setupMirrored }}
IDOL_DIH_ACI_PORT=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ .Values.dih.aciPort | int }}}

. "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"

function waitForLastEngine() {
    engines=2
    wait=30
    for i in $(seq $wait)
    do
      engines=$(curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_DIH_ACI_PORT}/a=getstatus" | sed "s@<host>@\n<host>@g" | grep -c "<host>")
      if [ "$engines" -eq 1 ]; then
        break
      fi
      sleep 1
    done
}

logfile=/opt/idol/dih/data/prestop.log
(
  echo "[$(date)] DIH waiting for child engines before shutdown."
  waitForAci localhost ${IDOL_DIH_ACI_PORT}
  waitForLastEngine
  echo "[$(date)] DIH is shutting down."
)  | tee -a "${logfile}"


{{- else }}
echo "Nothing to do in non-mirror mode"
{{- end }}
