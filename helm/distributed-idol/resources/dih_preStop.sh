# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
{{/* 
preStop hook is used in mirror mode to allow child engines a chance 
to run their preStop hooks before the DIH disappears (as they are unable
to tell the difference between scaledown and undeploy).
In non-mirror mode this is a no-op
*/}}
{{- if .Values.setupMirrored }}
function waitForAci() {
  exit_code=1
  while [ $exit_code -ne 0 ]; do
    curl -o - "http://$1:$2/a=getpid" | grep "<autn:pid>"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      sleep 1
    fi
  done
}

dihaciport=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dihPorts 0).container | int }}}

function waitForLastEngine() {
    engines=2
    wait=30
    for i in $(seq $wait)
    do
      engines=$(curl -o - "http://localhost:$dihaciport/a=getstatus" | sed "s@<host>@\n<host>@g" | grep -c "<host>")
      if [ "$engines" -eq 1 ]; then
        break
      fi
      sleep 1
    done
}

logfile=/opt/idol/dih/data/prestop.log

echo "[$(date)] DIH waiting for child engines before shutdown." | tee -a $logfile
waitForAci localhost $dihaciport
waitForLastEngine
echo "[$(date)] DIH is shutting down." | tee -a $logfile

{{- else }}
echo "Nothing to do in non-mirror mode"
{{- end }}
