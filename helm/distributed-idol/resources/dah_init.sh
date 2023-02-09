# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE
# This is run by the dah edit-config initContainer to populate initial dah config

logfile=/mnt/config/idol/edit-config.log

echo "[$(date)] Start dah init" | tee -a $logfile

name={{ .Values.contentName }}
# find the highest id of any detectable pod from {{ .Values.contentName }} statefulset
pods=$(nslookup $name | grep -o -E $name-[0-9]+ | sort -t - -k 4 -g)
maxid=0
if [ -z "$pods" ]
then
  echo "[$(date)] No content pods detected" | tee -a $logfile
else
  for p in $pods
  do
    echo "[$(date)] Detected pod $p" | tee -a $logfile
    id=$(echo $p | sed -e s/$name-//)
    if [ $id -gt $maxid ]
    then
      maxid=$id
    fi
  done
  echo "[$(date)] Max detected pod id: $maxid" | tee -a $logfile
fi
# this is the max id according to .Values.initialContentEngineCount
setupmaxid={{ (sub (.Values.initialContentEngineCount | int ) 1 | int) }}

if [ $setupmaxid -gt $maxid ] 
then
  maxid=$setupmaxid
fi

port=${IDOL_CONTENT_SERVICE_PORT_ACI_PORT:-{{ (index .Values.contentPorts 0).container | int }}}
distribution_idol_servers="Number=$((maxid+1))\n"
domain=$(cat /etc/resolv.conf | grep search | awk '{print $2}')
for i in `seq 0 $maxid`
do
  h={{ .Values.contentName }}-$i.{{ .Values.contentName }}.$domain
  echo "[$(date)] Adding $h:$port to config" | tee -a $logfile
  distribution_idol_servers="${distribution_idol_servers}\n[IDOLServer$i]\nHost=$h\nPort=$port\n"
done

sed s/XX_DISTRIBUTION_IDOL_SERVERS_XX/"$distribution_idol_servers"/ /mnt/config-map/dah.cfg > /mnt/config/idol/dah.cfg
cp /mnt/config/idol/dah.cfg /mnt/config/idol/dah.install.cfg