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

. "$( dirname "${BASH_SOURCE[0]}" )/common_utils.sh"

getIsPrimary
cd /content || exit
ln -sf /opt/idol/content/index ./index
if [[ ${is_primary} -eq 1 ]] 
then
  mkdir -p /opt/idol/archive/backups
  mkdir -p /opt/idol/archive/indexcommands
  export IDOL_COMPONENT_CFG=/etc/config/idol/content_primary.cfg
else
  export IDOL_COMPONENT_CFG=/etc/config/idol/content.cfg
fi
./run_idol.sh &
RUN_IDOL_PID=$!
trap 'kill "${RUN_IDOL_PID}"; wait "${RUN_IDOL_PID}"' SIGINT SIGTERM
wait "${RUN_IDOL_PID}"
echo "Content exited"