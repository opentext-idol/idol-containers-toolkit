#/bin/bash

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

source /${IDOL_COMPONENT}/prestart_scripts/oauth_tool_setup_functions

if [[ ! -e ${OAUTH_TOOL_CFG} ]]
then
    echo No oauth_tool.cfg provided at ${OAUTH_TOOL_CFG}: OAuth will not be automatically configured via oauth_tool
else
    echo Automatically configuring OAuth using oauth_tool and ${OAUTH_TOOL_CFG}
    handle_oauth_setup ${IDOL_COMPONENT} ${IDOL_COMPONENT_CFG} ${OAUTH_TOOL_CFG}
fi