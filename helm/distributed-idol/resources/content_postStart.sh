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

function restoreFromBackup() {
  local IDOL_PRIMARY_CONTENT_HOST=${IDOL_CONTENT_BASE_HOSTNAME}-0.${IDOL_CONTENT_BASE_HOSTNAME}.${domain}
  local restoreTime=$(date -Iseconds)
  local GETBACKUPDATA_FILE=gbd.xml
  curl -o ${GETBACKUPDATA_FILE} ${HTTP_REQ_PARAMS} \
  "${HTTP_SCHEME}://${IDOL_PRIMARY_CONTENT_HOST}:${IDOL_CONTENT_ACI_PORT}/action=getbackupdata&backupforrestoretime=${restoreTime}"
  local backupFile=$(sed "s/</\n</g" ${GETBACKUPDATA_FILE} | grep "<file" | awk -F">" {'print $2'})

  local parameters=""
  if [ "${backupFile}" == "" ];
  then
    echo "[$(date)] No backup to restore from. Restoring from archived index commands only."
    parameters="ReplayArchivePath=/opt/idol/archive/indexcommands&RestoreTime=$restoreTime"
  else
    local backupTimeEpochSeconds=$(sed "s/</\n</g" ${GETBACKUPDATA_FILE} | grep "<time" | awk -F">" {'print $2'})
    local backupTimeISO8601=$(date --date="@${backupTimeEpochSeconds}" -Iseconds)
    echo "[$(date)] Restoring from backup file ${backupFile} with time ${backupTimeISO8601} and archived index commands"
    parameters="path=$backupFile&BackupTime=$backupTimeISO8601&ReplayArchivePath=/opt/idol/archive/indexcommands&RestoreTime=$restoreTime"
  fi
  rm ${GETBACKUPDATA_FILE}
  echo "[$(date)] Sending DREINITIAL with restore parameters '${parameters}'"
  doDreinitial ${parameters}
}

function getInitialId() {
  initial_id=$(curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_CONTENT_ACI_PORT}/a=getstatus" | sed "s/</\n</g" | grep initialid | cut -d ">" -f2)
}

function getIndexerStatus() {
  index_status=$(curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_CONTENT_ACI_PORT}/a=indexergetstatus&index=$1" | sed "s/</\n</g" | grep status | cut -d ">" -f2)
}

function doDreinitial() {
  local other_params=${1:-}
  getInitialId
  echo "[$(date)] Previous initial id was $initial_id"
  local new_id=$(($initial_id+1))
  echo "[$(date)] Using initialid $new_id"
  curl ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_CONTENT_INDEX_PORT}/DREINITIAL?initialid=$new_id&${other_params}" 
  initial_id=0
  while [ $initial_id != $new_id ]; do
    getInitialId
    sleep 1
  done
  # Workaround DREINITIAL reporting as completing before replay of archived commands completes
  local index_id=0
  index_id=$(curl -o- ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_CONTENT_INDEX_PORT}/DRESYNC?" | grep INDEXID | cut -d "=" -f2)
  index_status=-7
  while [ $index_status != -1 ]; do
    getIndexerStatus "$index_id"
    sleep 5
  done
}

function postStartPrimary() {
  curl -o gs.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://localhost:${IDOL_CONTENT_INDEX_PORT}/DRECREATEDBASE?DREDBNAME=Default"
  local port=${IDOL_CONTENT_ACI_PORT}
  if getent hosts ${IDOL_DIH_HOSTNAME}; then
    echo "[$(date)] Extant DIH detected, adding $hostname to it."
    echo "[$(date)] Waiting for DIH to be ACI-available."
    waitForAci ${IDOL_DIH_HOSTNAME} ${IDOL_DIH_ACI_PORT}
    echo "[$(date)] DIH is ACI-available."
    curl -o gs.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=getstatus"
    sed "s/</\n</g" gs.xml | grep "host" | grep "${hostname}\."
    if [ $? -eq 1 ]; then
      echo "[$(date)] $hostname not found in DIH, adding it."
      curl -o dihadd.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=enginemanagement&engineaction=add&host=$hostname&port=$port&disabled=true"
      local dih_id=$(sed "s/</\n</g" dihadd.xml | grep "engine id" | grep "$hostname" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
      echo "[$(date)] DIH returned id ${dih_id} for this engine."
      curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=enginemanagement&engineaction=edit&id=${dih_id}&disabled=false"
      echo "[$(date)] Added $hostname to DIH."
      rm dihadd.xml
    else
      echo "[$(date)] $hostname found in DIH, not adding it."
    fi
    rm gs.xml
  else
    echo "[$(date)] No extant DIH detected."
  fi
  if getent hosts ${IDOL_DAH_HOSTNAME}; then
    echo "[$(date)] Extant DAH detected, adding $hostname to it."
    echo "[$(date)] Waiting for DAH to be ACI-available."
    waitForAci ${IDOL_DAH_HOSTNAME} ${IDOL_DAH_ACI_PORT}
    echo "[$(date)] DAH is ACI-available"
    curl -o gc.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=getchildren"
    sed "s/</\n</g" gc.xml | grep "host" | grep "$hostname"
    if [ $? -eq 1 ]; then
      echo "[$(date)] $hostname not found in DAH, adding it."
      curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=engineadd&enginehost=$hostname&engineport=$port"
      echo "[$(date)] Added $hostname to DAH"
    else
      echo "[$(date)] $hostname found in DAH, not adding it."
    fi
    curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=showstatus"
    local dah_id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "$hostname" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    echo "[$(date)] DAH returned id $dah_id for this engine."
    curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=PowerUp&EngineID=$dah_id"
    echo "[$(date)] Ensured this engine is powered up in DAH"
    rm engineshowstatus.xml
    rm gc.xml
  else
    echo "[$(date)] No extant DAH detected."
  fi
}

function postStartNonPrimary() {
  local port=${IDOL_CONTENT_ACI_PORT}
  if getent hosts ${IDOL_DIH_HOSTNAME}; then
    echo "[$(date)] Extant DIH detected, adding ${hostname} to it."
    echo "[$(date)] Waiting for DIH to be ACI-available."
    waitForAci ${IDOL_DIH_HOSTNAME} ${IDOL_DIH_ACI_PORT}
    echo "[$(date)] DIH is ACI-available."
    curl -o gs.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=getstatus"
    sed "s/</\n</g" gs.xml | grep "host" | grep "${hostname}"
    if [ $? -eq 1 ]; then
  {{- if not .Values.setupMirrored }}
      echo "[$(date)] ${hostname} not found in DIH. Ensuring clean data index"
      doDreinitial
  {{- end }}
      echo "[$(date)] Adding ${hostname} to DIH."
      curl -o dihadd.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=enginemanagement&engineaction=add&host=${hostname}&port=$port&disabled=true"
      local dih_id=$(sed "s/</\n</g" dihadd.xml | grep "engine id" | grep "$host" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
      echo "[$(date)] DIH returned id ${dih_id} for this engine."
  {{- if .Values.setupMirrored }}
      echo "[$(date)] This is a mirrored setup with an extant DIH. Restoring from backup"
      restoreFromBackup 
  {{- end }}
      curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_ACI_PORT}/a=enginemanagement&engineaction=edit&id=${dih_id}&disabled=false"
      echo "[$(date)] Added ${hostname} to DIH."
      rm dihadd.xml
    else
      echo "[$(date)] ${hostname} found in DIH, not adding and treating as extant engine."
  {{- if .Values.setupMirrored }}
      echo "[$(date)] This is a mirrored setup with an extant DIH. Restoring from backup"
      restoreFromBackup 
  {{- end }}
    fi
    rm gs.xml
  else
    echo "[$(date)] No extant DIH detected."
  fi
  if getent hosts ${IDOL_DAH_HOSTNAME}; then
    echo "[$(date)] Extant DAH detected, adding ${hostname} to it."
    echo "[$(date)] Waiting for DAH to be ACI-available."
    waitForAci ${IDOL_DAH_HOSTNAME} ${IDOL_DAH_ACI_PORT}
    echo "[$(date)] DAH is ACI-available"
    curl -o gc.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=getchildren"
    sed "s/</\n</g" gc.xml | grep "host" | grep "${hostname}"
    if [ $? -eq 1 ]; then
      echo "[$(date)] ${hostname} not found in DAH, adding it."
      curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=engineadd&enginehost=${hostname}&engineport=$port"
      echo "[$(date)] Added ${hostname} to DAH"
    else
      echo "[$(date)] ${hostname} found in DAH, not adding it."
    fi
    curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=showstatus"
    local dah_id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "${hostname}" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    echo "[$(date)] DAH returned id ${dah_id} for this engine."
    curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=PowerUp&EngineID=${dah_id}"
    echo "[$(date)] Ensured this engine is powered up in DAH"
    rm engineshowstatus.xml
    rm gc.xml
  else
    echo "[$(date)] No extant DAH detected."
  fi
}

set -o pipefail
logfile=/opt/idol/content/index/poststart.log
(
  . "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"

  getHostname
  getIsPrimary

  echo "[$(date)] hostname: ${hostname} (is_primary: ${is_primary})"

  waitForAci localhost ${IDOL_CONTENT_ACI_PORT}
  if [[ ${is_primary} -eq 1 ]] 
  then
    postStartPrimary
  else
    postStartNonPrimary
  fi
  # Final check that this Content is available
  waitForAci localhost ${IDOL_CONTENT_ACI_PORT}
) | tee -a "${logfile}"