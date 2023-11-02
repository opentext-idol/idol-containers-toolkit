#!/bin/bash

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

set -ex -o allexport
timeout 10m bash -c "until ${NIFI_TOOLKIT_HOME}/bin/cli.sh nifi current-user >/dev/null; do echo [\$(date)] Waiting for NiFi CLI...; sleep 5; done"