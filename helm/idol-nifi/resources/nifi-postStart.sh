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
(
    . $( dirname "${BASH_SOURCE[0]}" )/nifi-toolkit-utils.sh

    if [ -z "${JAVA_HOME}" ]
    then
        JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 | grep java.home | cut -d = -f 2 | xargs)
        export JAVA_HOME="$JAVA_HOME"
        echo ["$(date)"] Using auto-detected JAVA_HOME: "$JAVA_HOME"
    fi
    /scripts/nifiProperties.sh
    /scripts/security.sh

    statefulsetname=${POD_NAME%-*}
    grep "${statefulsetname}-0." /etc/hostname
    notprimary=$?
    if [ 1 == ${notprimary} ]; then
        echo ["$(date)"] Skipping post-start checks as non-primary instance
        exit 0
    fi

    NODECOUNT=
    nifitoolkit_nifi_getClusterNodeCount NODECOUNT
    if [ ${NODECOUNT} -gt 1 ]; then
        echo ["$(date)"] Skipping post-start checks as cluster is already running "( ${NODECOUNT} )"
        exit 0
    fi

    nifitoolkit_nifi_waitForCLI

    /scripts/connect-registry.sh
    if [ -f /scripts/prometheous-reporting.sh ]; then
        /scripts/prometheous-reporting.sh
    fi
    /scripts/import-flow.sh

    echo ["$(date)"] postStart completed
) | tee -a ${logfile}
