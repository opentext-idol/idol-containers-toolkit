# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

cd /content
ln -sf /opt/idol/content/index ./index
export IDOL_COMPONENT_CFG=/etc/config/idol/content.cfg

./run_idol.sh
