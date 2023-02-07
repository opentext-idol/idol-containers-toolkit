{{/* 
preStop hook is used in mirror mode to remove engine from DIH/DAH.
In non-mirror mode this is a no-op
*/}}
{{- if .Values.setupMirrored }}
function waitForAci() {
  exit_code=1
  while [ $exit_code -ne 0 ]; do
    wget -O- "http://$1:$2/a=getpid" | grep "<autn:pid>"
    exit_code=$?
    if [ $exit_code -ne 0 ]; then
      sleep 1
    fi
  done
}

function getDIHEngineID() {
  wget -Oenginedih.xml -nv -t 5 --retry-connrefused --waitretry=10 "http://idol-dih:$1/a=getstatus"
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

logfile=/opt/idol/content/index/prestop.log
getHostname
getIsPrimary

if [[ ${is_primary} -eq 1 ]] 
then
  echo "[$(date)] Nothing to do for primary engine." | tee -a $logfile
else
  echo "[$(date)] preStop starting." | tee -a $logfile
  port=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ (index .Values.contentPorts 0).container | int }}}
  if getent hosts {{ .Values.dihName }}; then
    dihaciport=${IDOL_DIH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dihPorts 0).container | int }}}
    dihindexport=${IDOL_DIH_SERVICE_PORT_INDEX_PORT:-{{ (index .Values.dihPorts 1).container | int }}}
    echo "[$(date)] Extant DIH detected, removing ourselves ($hostname) from it." | tee -a $logfile
    echo "[$(date)] Waiting for DIH to be ACI-available." | tee -a $logfile
    waitForAci idol-dih $dihaciport
    echo "[$(date)] DIH is ACI-available." | tee -a $logfile
    engineid=$(getDIHEngineID $dihaciport $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Removing $hostname from DIH." | tee -a $logfile
      echo "[$(date)] DIH returned id $engineid for this engine." | tee -a $logfile
      wget -nv -t 5 --retry-connrefused --waitretry=10 "http://idol-dih:$dihindexport/DREREDISTRIBUTE?RemoveGroup=$engineid"
      waitForDIHRemovedEngine $dihaciport $hostname
      echo "[$(date)] Removed $hostname from DIH." | tee -a $logfile
    else
      echo "[$(date)] $hostname not found in DIH, nothing to do." | tee -a $logfile
    fi
  else
    echo "[$(date)] No extant DIH detected." | tee -a $logfile
  fi

  function getDAHEngineID() {
    wget -Oengineshowstatus.xml -nv -t 5 --retry-connrefused --waitretry=10 "http://{{ .Values.dahName }}:$1/a=enginemanagement&engineaction=showstatus"
    id=$(sed "s/</\n</g" engineshowstatus.xml | grep "engine id" | grep "$2" | awk '{print $2}' | cut -d '=' -f2 | grep -o -E '[0-9]+')
    rm engineshowstatus.xml
    echo $id
  }

  if getent hosts {{ .Values.dahName }}; then
    dahaciport=${IDOL_DAH_SERVICE_PORT_ACI_PORT:-{{ (index .Values.dahPorts 0).container | int }}}
    echo "[$(date)] Extant DIH detected, powering down ourselves ($hostname) in it." | tee -a $logfile
    echo "[$(date)] Waiting for DAH to be ACI-available." | tee -a $logfile
    waitForAci idol-dah $dahaciport
    echo "[$(date)] DAH is ACI-available" | tee -a $logfile
    engineid=$(getDAHEngineID $dahaciport $hostname)
    if [ $engineid -gt -1 ]; then
      echo "[$(date)] Powering down $hostname in DAH." | tee -a $logfile
      echo "[$(date)] DAH returned id $engineid for this engine." | tee -a $logfile
      wget -O- -nv -t 5 --retry-connrefused --waitretry=10 "http://{{ .Values.dahName }}:$dahaciport/a=enginemanagement&engineaction=PowerDown&EngineID=$engineid"
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