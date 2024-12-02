#!/bin/sh

# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

HTTP_REQ_PARAMS="-k --silent --show-error --retry 5 --retry-connrefused --retry-max-time 10"
IDOL_CONTENT_ACI_PORT=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ .Values.content.aciPort | int }}}
IDOL_CONTENT_INDEX_PORT={{ .Values.content.indexPort | int }}
IDOL_CONTENT_BASE_HOSTNAME={{ .Values.content.name }}
IDOL_DAH_ACI_PORT=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ .Values.dah.aciPort | int }}}
IDOL_DAH_HOSTNAME={{ .Values.dah.name }}
IDOL_DIH_ACI_PORT=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ .Values.dih.aciPort | int }}}
IDOL_DIH_HOSTNAME={{ .Values.dih.name }}

MAX_POD_ID=0
# # this is the max id according to .Values.content.initialEngineCount
SETUP_MAX_ID={{ (sub (.Values.content.initialEngineCount | int ) 1 | int) }}


if [ -z ${IDOL_SSL} ]; then
    HTTP_SCHEME=http
else
    HTTP_SCHEME=https
fi

getHostname() {
  host=$(cat /etc/hostname)
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  hostname=${host}.${IDOL_CONTENT_BASE_HOSTNAME}.${domain}
}

getIsPrimary() {
  is_primary=0
{{- if .Values.setupMirrored }}
  getHostname
  serviceName="${IDOL_CONTENT_BASE_HOSTNAME}-0"
  if [ "${host}" = "${serviceName}" ]
  then
    is_primary=1
  fi
{{- end }}
}

waitForAci() {
  exit_code=1
  while [ $exit_code -ne 0 ]; do
    curl -o - ${HTTP_REQ_PARAMS} "${HTTP_SCHEME}://$1:$2/a=getpid" | grep "<autn:pid>"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      sleep 1
    fi
  done
}

getMaxPodId() {
  # find the highest id of any detectable pod from {{ .Values.content.name }} statefulset
  pods=$(nslookup "${IDOL_CONTENT_BASE_HOSTNAME}" | grep -o -E "${IDOL_CONTENT_BASE_HOSTNAME}-[0-9]+" | sort -t - -k 4 -g)
  if [ -z "$pods" ]
  then
    echo "[$(date)] No content pods detected"
  else
    for p in $pods
    do
      id
      echo "[$(date)] Detected pod ${p}"
      id=$(echo "${p}" | sed -e "s/${IDOL_CONTENT_BASE_HOSTNAME}-//")
      if [ "${id}" -gt "${MAX_POD_ID}" ]
      then
        MAX_POD_ID=${id}
      fi
    done
    echo "[$(date)] Max detected pod id: ${MAX_POD_ID}"
  fi
  if [ "${SETUP_MAX_ID}" -gt "${MAX_POD_ID}" ] 
  then
    MAX_POD_ID="${SETUP_MAX_ID}"
  fi
}

writeDistIdolConfigChanges() {
  srcConfig="${1}"
  destConfig="${2}"
  buffer="Number=$((MAX_POD_ID+1))\n"
  domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
  sslConfig=$([ -z ${IDOL_SSL} ] && echo "" || echo "SSLSettings")
  for i in $(seq 0 "${MAX_POD_ID}")
  do
    host="${IDOL_CONTENT_BASE_HOSTNAME}-${i}.${IDOL_CONTENT_BASE_HOSTNAME}.${domain}"
    echo "[$(date)] Adding ${host}:${IDOL_CONTENT_ACI_PORT} to config"
    buffer="${buffer}\n[IDOLServer${i}]\nHost=${host}\nPort=${IDOL_CONTENT_ACI_PORT}\nSSLConfig=${sslConfig}\n"
  done

  sed "s/XX_DISTRIBUTION_IDOL_SERVERS_XX/${buffer}/" "${srcConfig}" > "${destConfig}"
}
