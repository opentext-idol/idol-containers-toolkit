# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

cd /content
ln -sf /opt/idol/content/index ./index

# Use the content.cfg configuration file for our content engine, unless
# we're using the IDOL agentstore docker image - in which case use the
# agentstore.cfg file.
config_file="content.cfg"

if [ "{{ .Values.idolImage.repo }}" == "agentstore" ]; then
    config_file="agentstore.cfg"
fi

config_file_path="/etc/config/idol/${config_file}"
export IDOL_COMPONENT_CFG="$config_file_path"

./run_idol.sh
