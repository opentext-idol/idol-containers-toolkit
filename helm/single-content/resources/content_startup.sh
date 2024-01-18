# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

cd /content
ln -sf /opt/idol/content/index ./index

# Use the content.cfg configuration file for our content engine, unless
# we've provided an existingConfigMap - in which case assume
# that the file name has the form {existingConfigMap}.cfg.
export IDOL_COMPONENT_CFG="/etc/config/idol/${IDOL_COMPONENT:-content}.cfg"

./run_idol.sh
