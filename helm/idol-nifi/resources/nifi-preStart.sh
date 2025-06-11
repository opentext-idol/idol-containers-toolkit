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

logfile=/opt/nifi/nifi-current/logs/pre-start.log
(
    if [ -z "${JAVA_HOME}" ]
    then
        JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 | grep java.home | cut -d = -f 2 | xargs)
        export JAVA_HOME="$JAVA_HOME"
        echo ["$(date)"] Using auto-detected JAVA_HOME: "$JAVA_HOME"
    fi
    /scripts/nifiProperties.sh
    /scripts/security.sh

    for script in /prestart_scripts/*.sh
    do
        [ -f "$script" ] && source "$script"
    done

    echo ["$(date)"] preStart completed
) | tee -a ${logfile}
