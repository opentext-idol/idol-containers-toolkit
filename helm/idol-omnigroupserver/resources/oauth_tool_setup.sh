#!/bin/bash

# Sections / paths are written into our configfiles with surrounding
# characters. Remove these surrounding characters.
function prepare_string() {
    echo $1 | cut -c 2- | rev | cut -c 2- | rev
}

function generate_missing_oauth_config() {
    OAUTH_TOOL_PATH=$1
    OAUTH_TOOL_CFG=$2
    OAUTH_TOOL_CFG_SECTION=$3
    REQUIRED_FILENAME=$4

    if [[ -e ${REQUIRED_FILENAME} ]]
    then
        echo Cowardly not overwriting existing file ${REQUIRED_FILENAME}
        return 0
    fi

    ${OAUTH_TOOL_PATH} ${OAUTH_TOOL_CFG} ${OAUTH_TOOL_CFG_SECTION}
    if [ $? -ne 0 ]
    then
        echo ${OAUTH_TOOL_PATH} ${OAUTH_TOOL_CFG} ${OAUTH_TOOL_CFG_SECTION} failed!
        return 1
    fi

    # oauth_tool.exe succeeded and will have generated oauth.cfg.
    # This requires renaming to the required filename.
    mv ./oauth.cfg ${REQUIRED_FILENAME}
    if [ $? -ne 0 ]
    then
        echo Could not move ./oauth.cfg to ${REQUIRED_FILENAME}
        return 1
    fi

    echo Generated ${REQUIRED_FILENAME} for ${OAUTH_TOOL_CFG_SECTION} OAuth setup.
    return 0
}

# Find lines in the component config that match the form
# [$section_name] < "$configpath" [OAUTH]
# For each matching line, the file at $configpath must
# be generated via oauth_tool if it does not currently exist.
function handle_oauth_setup() {
    COMPONENT_NAME=$1
    COMPONENT_CFG=$2
    OAUTH_TOOL_CFG=$3

    # /${COMPONENT_NAME}/oauth_tool.exe must exist as an executable for this to succeed
    OAUTH_TOOL_PATH=${COMPONENT_NAME}/oauth_tool.exe
    if [[ ! -x ${OAUTH_TOOL_PATH} ]]
    then
        echo Error: Could not find ${OAUTH_TOOL_PATH} for OAuth setup
        return 1
    fi

    if [[ ! -e ${COMPONENT_CFG} ]];
    then
        echo Error: Could not find ${COMPONENT_CFG} to derive OAuth sections for OAuth setup
        return 1
    fi

    if [[ ! -e ${OAUTH_TOOL_CFG} ]]
    then
        echo Error: Could not find ${OAUTH_TOOL_CFG} for configuring OAuth setup
        return 1
    fi

    unset BACKUP_CONFIG
    if [[ -e ./oauth.cfg ]]
    then
        BACKUP_CONFIG="oauth.cfg.$(date +%s%N).bak"
        echo oauth.cfg is overwritten by oauth_tool.exe calls, but one already exists. Renaming to ${BACKUP_CONFIG}
        mv ./oauth.cfg ./${BACKUP_CONFIG}
    fi

    grep -E "\[[^]]+]\s+<\s+.+\s+\[OAUTH\]" ${COMPONENT_CFG} | {
        while read RAW_SECTION LT_SYMBOL RAW_CONFIGPATH OAUTH
        do
            SECTION=$(prepare_string ${RAW_SECTION})
            CONFIGPATH=$(prepare_string ${RAW_CONFIGPATH})
            generate_missing_oauth_config ${OAUTH_TOOL_PATH} ${OAUTH_TOOL_CFG} ${SECTION} ${CONFIGPATH}
            if [ $? -ne 0 ]
            then
                echo Failed to generate ${CONFIGPATH} for ${SECTION}
                return 1
            fi
        done
    }

    if [[ -v BACKUP_CONFIG ]]
    then
        echo Restoring original oauth.cfg from ${BACKUP_CONFIG}
        mv ./${BACKUP_CONFIG} ./oauth.cfg
        unset BACKUP_CONFIG
    fi

    return 0
}