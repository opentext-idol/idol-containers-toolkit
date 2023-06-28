# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
HTTP_REQ_PARAMS="--silent --show-error --retry 5 --retry-connrefused --retry-max-time 10"

function getHostname() {
  host=$(cat /etc/hostname)
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  hostname=${host}.{{ .Values.contentName }}.${domain}
}

function getIsPrimary() {
  is_primary=0
{{- if .Values.setupMirrored }}
  getHostname
  serviceName="{{ .Values.contentName }}-0."
  if [[ ${hostname::${#serviceName}} == ${serviceName} ]]
  then
    is_primary=1
  fi
{{- end }}
}

function restoreFromBackup() {
  logfile=$1
  if [ "${IDOL_PRIMARY_CONTENT_HOST}" == "" ];
  then
    echo "[$(date)] No content primary to restore from, skipping restore." | tee -a $logfile
    return
  fi
  restoreTime=$(date -Iseconds)
  GETBACKUPDATA_FILE=gbd.xml
  curl -o ${GETBACKUPDATA_FILE} ${HTTP_REQ_PARAMS} \
  "http://${IDOL_PRIMARY_CONTENT_HOST}:${IDOL_CONTENT_ACI_PORT}/action=getbackupdata&backupforrestoretime=${restoreTime}"
  backupFile=$(sed "s/</\n</g" ${GETBACKUPDATA_FILE} | grep "<file" | awk -F">" {'print $2'})

  parameters=""
  if [ "${backupFile}" == "" ];
  then
    echo "[$(date)] No backup to restore from. Restoring from archived index commands only." | tee -a $logfile
    parameters="ReplayArchivePath=/opt/idol/archive/indexcommands&RestoreTime=$restoreTime"
  else
    backupTimeEpochSeconds=$(sed "s/</\n</g" ${GETBACKUPDATA_FILE} | grep "<time" | awk -F">" {'print $2'})
    backupTimeISO8601=$(date --date="@${backupTimeEpochSeconds}" -Iseconds)
    echo "[$(date)] Restoring from backup file ${backupFile} with time ${backupTimeISO8601} and archived index commands" | tee -a $logfile
    parameters="path=$backupFile&BackupTime=$backupTimeISO8601&ReplayArchivePath=/opt/idol/archive/indexcommands&RestoreTime=$restoreTime"
  fi
  rm ${GETBACKUPDATA_FILE}
  echo "[$(date)] Sending DREINITIAL with restore parameters '${parameters}'" | tee -a $logfile
  doDreinitial ${parameters}
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

function getInitialId() {
  initial_id=$(curl -o - ${HTTP_REQ_PARAMS} "http://localhost:{{ (index .Values.contentPorts 0).container | int }}/a=getstatus" | sed "s/</\n</g" | grep initialid | cut -d ">" -f2)
}

function getIndexerStatus() {
  index_status=$(curl -o - ${HTTP_REQ_PARAMS} "http://localhost:{{ (index .Values.contentPorts 0).container | int }}/a=indexergetstatus&index=$1" | sed "s/</\n</g" | grep status | cut -d ">" -f2)
}

function doDreinitial() {
  other_params=${1:-}
  getInitialId
  echo "[$(date)] Previous initial id was $initial_id" | tee -a $logfile
  new_id=$(($initial_id+1))
  echo "[$(date)] Using initialid $new_id" | tee -a $logfile
  curl ${HTTP_REQ_PARAMS} "http://localhost:{{ (index .Values.contentPorts 1).container | int }}/DREINITIAL?initialid=$new_id&${other_params}" 
  initial_id=0
  while [ $initial_id != $new_id ]; do
    getInitialId
    sleep 1
  done
  # Workaround DREINITIAL reporting as completing before replay of archived commands completes
  index_id = $(curl -o- ${HTTP_REQ_PARAMS} "http://localhost:{{ (index .Values.contentPorts 1).container | int }}/DRESYNC?" | grep INDEXID | cut -d "=" -f2)
  index_status=-7
  while [ $index_status != -1 ]; do
    getIndexerStatus "$index_id"
    sleep 5
  done
}

logfile=/opt/idol/content/index/poststart.log
getHostname
getIsPrimary
IDOL_PRIMARY_CONTENT_HOST={{ .Values.contentName }}-0.{{ .Values.contentName }}.${domain}
IDOL_CONTENT_ACI_PORT=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ (index .Values.contentPorts 0).container | int }}}
echo "[$(date)] hostname: ${hostname} (is_primary: ${is_primary})" | tee -a $logfile

waitForAci localhost ${IDOL_CONTENT_ACI_PORT}
if [[ ${is_primary} -eq 1 ]] 
then
  curl -o gs.xml ${HTTP_REQ_PARAMS} "http://localhost:{{ (index .Values.contentPorts 1).container | int }}/DRECREATEDBASE?DREDBNAME=Default"
  port=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ (index .Values.contentPorts 0).container | int }}}
  if getent hosts {{ .Values.dihName }}; then
    dihaciport=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dihPorts 0).container | int }}}
    echo "[$(date)] Extant DIH detected, adding $hostname to it." | tee -a $logfile
    echo "[$(date)] Waiting for DIH to be ACI-available." | tee -a $logfile
    waitForAci {{ .Values.dihName }} $dihaciport
    echo "[$(date)] DIH is ACI-available." | tee -a $logfile
    curl -o gs.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=getstatus"
    sed "s/</\n</g" gs.xml | grep "host" | grep "${hostname}\."
    if [ $? -eq 1 ]; then
      echo "[$(date)] $hostname not found in DIH, adding it." | tee -a $logfile
      curl -o dihadd.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=enginemanagement&engineaction=add&host=$hostname&port=$port&disabled=true"
      id=$(sed "s/</\n</g" dihadd.xml | grep "engine id" | grep "$hostname" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
      echo "[$(date)] DIH returned id $id for this engine." | tee -a $logfile
      curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=enginemanagement&engineaction=edit&id=$id&disabled=false"
      echo "[$(date)] Added $hostname to DIH." | tee -a $logfile
      rm dihadd.xml
    else
      echo "[$(date)] $hostname found in DIH, not adding it." | tee -a $logfile
    fi
    rm gs.xml
  else
    echo "[$(date)] No extant DIH detected." | tee -a $logfile
  fi
  if getent hosts {{ .Values.dahName }}; then
    dahaciport=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dahPorts 0).container | int }}}
    echo "[$(date)] Extant DAH detected, adding $hostname to it." | tee -a $logfile
    echo "[$(date)] Waiting for DAH to be ACI-available." | tee -a $logfile
    waitForAci {{ .Values.dahName }} $dahaciport
    echo "[$(date)] DAH is ACI-available" | tee -a $logfile
    curl -o gc.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=getchildren"
    sed "s/</\n</g" gc.xml | grep "host" | grep "$hostname"
    if [ $? -eq 1 ]; then
      echo "[$(date)] $hostname not found in DAH, adding it." | tee -a $logfile
      curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=engineadd&enginehost=$hostname&engineport=$port"
      echo "[$(date)] Added $hostname to DAH" | tee -a $logfile
    else
      echo "[$(date)] $hostname found in DAH, not adding it." | tee -a $logfile
    fi
    curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=showstatus"
    id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "$hostname" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    echo "[$(date)] DAH returned id $id for this engine." | tee -a $logfile
    curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=PowerUp&EngineID=$id"
    echo "[$(date)] Ensured this engine is powered up in DAH" | tee -a $logfile
    rm engineshowstatus.xml
    rm gc.xml
  else
    echo "[$(date)] No extant DAH detected." | tee -a $logfile
  fi
##
else
  port=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ (index .Values.contentPorts 0).container | int }}}
  if getent hosts {{ .Values.dihName }}; then
    dihaciport=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dihPorts 0).container | int }}}
    echo "[$(date)] Extant DIH detected, adding ${hostname} to it." | tee -a $logfile
    echo "[$(date)] Waiting for DIH to be ACI-available." | tee -a $logfile
    waitForAci {{ .Values.dihName }} $dihaciport
    echo "[$(date)] DIH is ACI-available." | tee -a $logfile
    curl -o gs.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=getstatus"
    sed "s/</\n</g" gs.xml | grep "host" | grep "${hostname}"
    if [ $? -eq 1 ]; then
  {{- if not .Values.setupMirrored }}
      echo "[$(date)] ${hostname} not found in DIH. Ensuring clean data index" | tee -a $logfile
      doDreinitial
  {{- end }}
      echo "[$(date)] Adding ${hostname} to DIH." | tee -a $logfile
      curl -o dihadd.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=enginemanagement&engineaction=add&host=${hostname}&port=$port&disabled=true"
      id=$(sed "s/</\n</g" dihadd.xml | grep "engine id" | grep "$host" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
      echo "[$(date)] DIH returned id $id for this engine." | tee -a $logfile
  {{- if .Values.setupMirrored }}
      echo "[$(date)] This is a mirrored setup with an extant DIH. Restoring from backup" | tee -a $logfile
      restoreFromBackup $logfile
  {{- end }}
      curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dihName }}:$dihaciport/a=enginemanagement&engineaction=edit&id=$id&disabled=false"
      echo "[$(date)] Added ${hostname} to DIH." | tee -a $logfile
      rm dihadd.xml
    else
      echo "[$(date)] ${hostname} found in DIH, not adding and treating as extant engine." | tee -a $logfile
  {{- if .Values.setupMirrored }}
      echo "[$(date)] This is a mirrored setup with an extant DIH. Restoring from backup" | tee -a $logfile
      restoreFromBackup $logfile
  {{- end }}
    fi
    rm gs.xml
  else
    echo "[$(date)] No extant DIH detected." | tee -a $logfile
  fi
  if getent hosts {{ .Values.dahName }}; then
    dahaciport=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dahPorts 0).container | int }}}
    echo "[$(date)] Extant DAH detected, adding ${hostname} to it." | tee -a $logfile
    echo "[$(date)] Waiting for DAH to be ACI-available." | tee -a $logfile
    waitForAci {{ .Values.dahName }} $dahaciport
    echo "[$(date)] DAH is ACI-available" | tee -a $logfile
    curl -o gc.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=getchildren"
    sed "s/</\n</g" gc.xml | grep "host" | grep "${hostname}"
    if [ $? -eq 1 ]; then
      echo "[$(date)] ${hostname} not found in DAH, adding it." | tee -a $logfile
      curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=engineadd&enginehost=${hostname}&engineport=$port"
      echo "[$(date)] Added ${hostname} to DAH" | tee -a $logfile
    else
      echo "[$(date)] ${hostname} found in DAH, not adding it." | tee -a $logfile
    fi
    curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=showstatus"
    id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "${hostname}" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    echo "[$(date)] DAH returned id $id for this engine." | tee -a $logfile
    curl -o - ${HTTP_REQ_PARAMS} "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=PowerUp&EngineID=$id"
    echo "[$(date)] Ensured this engine is powered up in DAH" | tee -a $logfile
    rm engineshowstatus.xml
    rm gc.xml
  else
    echo "[$(date)] No extant DAH detected." | tee -a $logfile
  fi
fi
# Final check that this Content is available
waitForAci localhost ${IDOL_CONTENT_ACI_PORT}