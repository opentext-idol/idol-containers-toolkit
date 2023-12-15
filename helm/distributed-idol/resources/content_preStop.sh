# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
{{/* 
preStop hook is used in mirror mode to remove engine from DIH/DAH.
In non-mirror mode this is a no-op
*/}}
{{- if .Values.setupMirrored }}
HTTP_REQ_PARAMS="--silent --show-error --retry 5 --retry-connrefused --retry-max-time 10"
IDOL_CONTENT_ACI_PORT=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ .Values.content.aciPort | int }}}
IDOL_CONTENT_INDEX_PORT={{ .Values.content.indexPort | int }}
IDOL_CONTENT_BASE_HOSTNAME={{ .Values.content.name }}
IDOL_DAH_ACI_PORT=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ .Values.dah.aciPort | int }}}
IDOL_DAH_HOSTNAME={{ .Values.dah.name }}
IDOL_DIH_ACI_PORT=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ .Values.dih.aciPort | int }}}
IDOL_DIH_INDEX_PORT=${IDOL_DIH_SERVICE_PORT_INDEX_PORT:-{{ .Values.dih.indexPort | int }}}
IDOL_DIH_HOSTNAME={{ .Values.dih.name }}

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

function getDIHEngineID() {
  curl -o enginedih.xml ${HTTP_REQ_PARAMS} "http://${IDOL_DIH_HOSTNAME}:$1/a=getstatus"
  id=$(sed "s@<engine@\n<engine@g" enginedih.xml | grep "$2" | awk '{match($0, /<group>([0-9]+)<\/group>/); print substr($0, RSTART, RLENGTH)}' | awk '{match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH)}')
  rm enginedih.xml
  echo $id
}

function waitForDIHRemovedEngine() {
  result=1
  while [ $result -ne -1 ]; do
    result=$(getDIHEngineID $1 $2)
    if [ $result -ne -1 ]; then
      sleep 1
    fi
  done
}

function getHostname() {
  host=$(cat /etc/hostname)
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  hostname=${host}.${IDOL_CONTENT_BASE_HOSTNAME}.${domain}
}

function getIsPrimary() {
  is_primary=0
{{- if .Values.setupMirrored }}
  getHostname
  serviceName="${IDOL_CONTENT_BASE_HOSTNAME}-0."
  if [[ ${hostname::${#serviceName}} == ${serviceName} ]]
  then
    is_primary=1
  fi
{{- end }}
}

logfile=/opt/idol/content/index/prestop.log
getHostname
getIsPrimary

if [[ ${is_primary} -eq 1 ]] 
then
  echo "[$(date)] Nothing to do for primary engine." | tee -a $logfile
else
  echo "[$(date)] preStop starting." | tee -a $logfile
  port=${IDOL_CONTENT_ACI_PORT}
  if getent hosts ${IDOL_DIH_HOSTNAME}; then
    echo "[$(date)] Extant DIH detected, removing ourselves ($hostname) from it." | tee -a $logfile
    echo "[$(date)] Waiting for DIH to be ACI-available." | tee -a $logfile
    waitForAci ${IDOL_DIH_HOSTNAME} ${IDOL_DIH_ACI_PORT}
    echo "[$(date)] DIH is ACI-available." | tee -a $logfile
    engineid=$(getDIHEngineID ${IDOL_DIH_ACI_PORT} $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Removing $hostname from DIH." | tee -a $logfile
      echo "[$(date)] DIH returned id $engineid for this engine." | tee -a $logfile
      curl ${HTTP_REQ_PARAMS} "http://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_INDEX_PORT}/DREREDISTRIBUTE?RemoveGroup=$engineid"
      waitForDIHRemovedEngine ${IDOL_DIH_ACI_PORT} $hostname
      echo "[$(date)] Removed $hostname from DIH." | tee -a $logfile
    else
      echo "[$(date)] $hostname not found in DIH, nothing to do." | tee -a $logfile
    fi
  else
    echo "[$(date)] No extant DIH detected." | tee -a $logfile
  fi

  function getDAHEngineID() {
    curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS}  "http://${IDOL_DAH_HOSTNAME}:$1/a=enginemanagement&engineaction=showstatus"
    id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "$2" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    rm engineshowstatus.xml
    echo $id
  }

  if getent hosts ${IDOL_DAH_HOSTNAME}; then
    echo "[$(date)] Extant DIH detected, powering down ourselves ($hostname) in it." | tee -a $logfile
    echo "[$(date)] Waiting for DAH to be ACI-available." | tee -a $logfile
    waitForAci idol-dah ${IDOL_DAH_ACI_PORT}
    echo "[$(date)] DAH is ACI-available" | tee -a $logfile
    engineid=$(getDAHEngineID ${IDOL_DAH_ACI_PORT} $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Powering down $hostname in DAH." | tee -a $logfile
      echo "[$(date)] DAH returned id $engineid for this engine." | tee -a $logfile
      curl -o - ${HTTP_REQ_PARAMS}  "http://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=PowerDown&EngineID=$engineid"
      echo "[$(date)] Powered down $hostname in DAH" | tee -a $logfile
    else
      echo "[$(date)] $hostname not found in DAH, nothing to do." | tee -a $logfile
    fi
  else
    echo "[$(date)] No extant DAH detected." | tee -a $logfile
  fi
  echo "[$(date)] preStop completed." | tee -a $logfile
fi

{{- else }}
echo "Nothing to do in non-mirror mode"
{{- end }}