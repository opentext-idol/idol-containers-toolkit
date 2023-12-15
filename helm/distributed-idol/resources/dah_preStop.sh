# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
{{/* 
preStop hook is used in mirror mode to allow child engines a chance 
to run their preStop hooks before the DAH disappears (as they are unable
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

dahaciport=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ .Values.dah.aciPort | int }}}

function waitForLastEngine() {
    engines=2
    wait=30
    for i in $(seq $wait)
    do
      engines=$(curl -o - "http://localhost:$dahaciport/a=enginemanagement&engineaction=showstatus" | sed "s@<engine @\n<engine @g" | grep -c "<engine ")
      if [ "$engines" -eq 1 ]; then
        break
      fi
      sleep 1
    done
}

logfile=/etc/config/idol/dah_prestop.log

echo "[$(date)] DAH waiting for child engines before shutdown." | tee -a $logfile
waitForAci localhost $dahaciport
waitForLastEngine
echo "[$(date)] DAH is shutting down." | tee -a $logfile

{{- else }}
echo "Nothing to do in non-mirror mode"
{{- end }}
