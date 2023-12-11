# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

function getHostname() {
  host=$(cat /etc/hostname)
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  hostname=${host}.{{ .Values.name }}.${domain}
}

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

logfile=/opt/idol/content/index/poststart.log
getHostname

IDOL_CONTENT_ACI_PORT=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ .Values.aciPort | int }}}
echo "[$(date)] hostname: ${hostname}" | tee -a $logfile

# Final check that this Content is available
waitForAci localhost ${IDOL_CONTENT_ACI_PORT}