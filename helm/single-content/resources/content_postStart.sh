# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

source /content/startup_utils.sh

function getHostname() {
  host=$(cat /etc/hostname)
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  hostname=${host}.{{ .Values.name }}.${domain}
}

logfile=/opt/idol/content/index/poststart.log
getHostname

IDOL_CONTENT_ACI_PORT=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ .Values.aciPort | int }}}
echo "[$(date)] hostname: ${hostname}" | tee -a $logfile

# Final check that this Content is available
waitForAci localhost:${IDOL_CONTENT_ACI_PORT}