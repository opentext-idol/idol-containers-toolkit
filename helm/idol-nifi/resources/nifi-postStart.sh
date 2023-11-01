#! /bin/bash
logfile=/opt/nifi/nifi-current/logs/post-start.log
/scripts/security.sh | tee -a ${logfile}
/scripts/wait.sh | tee -a ${logfile}
/scripts/connect-registry.sh | tee -a ${logfile}
/scripts/import-flow.sh | tee -a ${logfile}
echo [$(date)] postStart completed | tee -a ${logfile}