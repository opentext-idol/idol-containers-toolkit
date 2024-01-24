#/bin/bash

source /${IDOL_COMPONENT}/prestart_scripts/oauth_tool_setup_functions

if [[ ! -e ${OAUTH_TOOL_CFG} ]]
then
    echo No oauth_tool.cfg provided at ${OAUTH_TOOL_CFG}: OAuth will not be automatically configured via oauth_tool
else
    echo Automatically configuring OAuth using oauth_tool and ${OAUTH_TOOL_CFG}
    handle_oauth_setup ${IDOL_COMPONENT} ${IDOL_COMPONENT_CFG} ${OAUTH_TOOL_CFG}
fi