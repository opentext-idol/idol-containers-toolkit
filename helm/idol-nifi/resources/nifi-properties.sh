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

scripts_dir="/opt/nifi/scripts"
[ -f "${scripts_dir}/common.sh" ] && . "${scripts_dir}/common.sh"

prop_replace "nifi.content.repository.archive.enabled" "${NIFI_CONTENT_REPOSITORY_ARCHIVE_ENABLED:-false}"