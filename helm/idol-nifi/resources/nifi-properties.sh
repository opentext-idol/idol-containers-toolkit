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

prop_replace "nifi.cluster.node.read.timeout" "${NIFI_CLUSTER_NODE_READ_TIMEOUT:-5 sec}"
prop_replace "nifi.cluster.node.connection.timeout" "${NIFI_CLUSTER_NODE_CONNECTION_TIMEOUT:-5 sec}"
prop_replace "nifi.cluster.node.event.history.size" "${NIFI_CLUSTER_NODE_EVENT_HISTORY_SIZE:-25}"
prop_replace "nifi.cluster.protocol.heartbeat.interval" "${NIFI_CLUSTER_PROTOCOL_HEARTBEAT_INTERVAL:-5 sec}"