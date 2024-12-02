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

# This is run by the dih edit-config initContainer to populate initial dih config

. "/scripts/distributed-idol/common_utils.sh"

function checkMirrorModeChange() {
  if [ -e /mnt/store/dih/dih.cfg ]
  then 
    local cfg_mirrormode
    local want_mirrormode
    cfg_mirrormode=$(grep MirrorMode /mnt/store/dih/dih.cfg)
    want_mirrormode=$(grep MirrorMode /mnt/config-map/dih.cfg)
    if [ "${cfg_mirrormode}" != "${want_mirrormode}" ]
    then 
      echo "[$(date)] Detected an attempt to alter MirrorMode configuration (${cfg_mirrormode} -> ${want_mirrormode}). Aborting."
      exit 1; 
    fi
    echo "[$(date)] No modifications made to extant dih.cfg."
    exit 0;
  fi
}

logfile=/mnt/store/dih/edit-config.log
(
  echo "[$(date)] Start dih init" 
  checkMirrorModeChange
  getMaxPodId
  writeDistIdolConfigChanges /mnt/config-map/dih.cfg /mnt/store/dih/dih.install.cfg
) | tee -a "${logfile}"









