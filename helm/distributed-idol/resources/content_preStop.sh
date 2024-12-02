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
preStop hook is used in mirror mode to remove engine from DIH/DAH.
In non-mirror mode this is a no-op
*/}}
function getDIHEngineID() {
  curl -o enginedih.xml ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:$1/a=getstatus"
  local id=$(sed "s@<engine@\n<engine@g" enginedih.xml | grep "$2" | awk '{match($0, /<group>([0-9]+)<\/group>/); print substr($0, RSTART, RLENGTH)}' | awk '{match($0, /[0-9]+/); print substr($0, RSTART, RLENGTH)}')
  rm enginedih.xml
  echo ${id}
}

function waitForDIHRemovedEngine() {
  local result=1
  while [ $result -ne -1 ]; do
    result=$(getDIHEngineID $1 $2)
    if [ $result -ne -1 ]; then
      sleep 1
    fi
  done
}

function getDAHEngineID() {
  curl -o engineshowstatus.xml ${HTTP_REQ_PARAMS}  "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:$1/a=enginemanagement&engineaction=showstatus"
  local id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "$2" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
  rm engineshowstatus.xml
  echo ${id}
}

function handleDIH() {
  if getent hosts ${IDOL_DIH_HOSTNAME}; then
    echo "[$(date)] Extant DIH detected, removing ourselves ($hostname) from it."
    echo "[$(date)] Waiting for DIH to be ACI-available."
    waitForAci ${IDOL_DIH_HOSTNAME} ${IDOL_DIH_ACI_PORT}
    echo "[$(date)] DIH is ACI-available."
    local engineid=$(getDIHEngineID ${IDOL_DIH_ACI_PORT} $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Removing $hostname from DIH."
      echo "[$(date)] DIH returned id $engineid for this engine."
      curl ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://${IDOL_DIH_HOSTNAME}:${IDOL_DIH_INDEX_PORT}/DREREDISTRIBUTE?RemoveGroup=$engineid"
      waitForDIHRemovedEngine ${IDOL_DIH_ACI_PORT} $hostname
      echo "[$(date)] Removed $hostname from DIH."
    else
      echo "[$(date)] $hostname not found in DIH, nothing to do."
    fi
  else
    echo "[$(date)] No extant DIH detected."
  fi
}

function handleDAH() {
  if getent hosts ${IDOL_DAH_HOSTNAME}; then
    echo "[$(date)] Extant DAH detected, powering down ourselves ($hostname) in it."
    echo "[$(date)] Waiting for DAH to be ACI-available."
    waitForAci idol-dah ${IDOL_DAH_ACI_PORT}
    echo "[$(date)] DAH is ACI-available"
    local engineid=$(getDAHEngineID ${IDOL_DAH_ACI_PORT} $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Powering down $hostname in DAH."
      echo "[$(date)] DAH returned id $engineid for this engine."
      curl -o - ${HTTP_REQ_PARAMS}  "${HTTP_SCHEME}://${IDOL_DAH_HOSTNAME}:${IDOL_DAH_ACI_PORT}/a=enginemanagement&engineaction=PowerDown&EngineID=$engineid"
      echo "[$(date)] Powered down $hostname in DAH"
    else
      echo "[$(date)] $hostname not found in DAH, nothing to do."
    fi
  else
    echo "[$(date)] No extant DAH detected."
  fi
}

logfile=/opt/idol/content/index/prestop.log
(
  {{- if .Values.setupMirrored }}  
  . "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"
  getHostname
  getIsPrimary

  if [[ ${is_primary} -eq 1 ]] 
  then
    echo "[$(date)] Nothing to do for primary engine."
  else
    echo "[$(date)] preStop starting."
    handleDIH
    handleDAH
    echo "[$(date)] preStop completed."
  fi

  {{- else }}
  echo "[$(date)] Nothing to do in non-mirror mode"
  {{- end }}
) | tee -a "${logfile}"
