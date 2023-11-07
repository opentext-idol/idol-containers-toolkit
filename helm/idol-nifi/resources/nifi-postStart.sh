#! /bin/bash

# BEGIN COPYRIGHT NOTICE
# Copyright 2023 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

logfile=/opt/nifi/nifi-current/logs/post-start.log
/scripts/security.sh | tee -a ${logfile}
/scripts/wait.sh | tee -a ${logfile}
/scripts/connect-registry.sh | tee -a ${logfile}
/scripts/import-flow.sh | tee -a ${logfile}
echo [$(date)] postStart completed | tee -a ${logfile}