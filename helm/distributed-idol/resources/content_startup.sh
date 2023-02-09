# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
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

getIsPrimary
cd /content
ln -sf /opt/idol/content/index ./index
if [[ ${is_primary} -eq 1 ]] 
then
  mkdir -p /opt/idol/archive/backups
  mkdir -p /opt/idol/archive/indexcommands
  export IDOL_COMPONENT_CFG=/etc/config/idol/content_primary.cfg
else
  export IDOL_COMPONENT_CFG=/etc/config/idol/content.cfg
fi
./run_idol.sh
