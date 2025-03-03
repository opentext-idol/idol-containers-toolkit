#! /bin/sh

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

# This is run by the dah edit-config initContainer to populate initial dah config

. "/scripts/distributed-idol/common_utils.sh"

logfile=/mnt/config/idol/edit-config.log
(
  echo "[$(date)] Start dah init"
  getMaxPodId
  writeDistIdolConfigChanges /mnt/config-map/dah.cfg /mnt/config/idol/dah.cfg
  cp /mnt/config/idol/dah.cfg /mnt/config/idol/dah.install.cfg
) | tee -a "${logfile}"
