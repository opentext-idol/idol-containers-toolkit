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

logfile=/opt/nifi/nifi-current/logs/pre-stop.log
(
    grep nifi-0. /etc/hostname
    notprimary=$?
    if [ 0 == ${notprimary} ]; then
        echo Skipping pre-stop as primary instance.
        exit 0
    fi

    host=${POD_NAME%-*}-0.${NIFI_WEB_HTTP_HOST#*.}
    echo Primary instance host $host

    port=$NIFI_WEB_HTTP_PORT
    echo Primary instance port $port

    cluster_node_id=`curl -s http://$NIFI_WEB_HTTP_HOST:$NIFI_WEB_HTTP_PORT/nifi-api/controller/cluster | jq -r ".cluster.nodes[] | select(.address==\"$NIFI_WEB_HTTP_HOST\") | .nodeId "`
    echo Cluster node id $cluster_node_id

    setAndWaitForStatus () {
        echo Setting status $1
        cluster_node_status=`curl -s -X PUT http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id -H 'Content-Type: application/json' -d "{\"node\":{\"nodeId\":\"$cluster_node_id\",\"status\": \"$1\"}}" | jq .node.status -r`
        while [ "$cluster_node_status" != "$2" ]
        do
            echo Waiting for status $2, status is $cluster_node_status
            sleep 1
            cluster_node_status=`curl -s http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id | jq .node.status -r`
        done
        echo Status reached $cluster_node_status
    }

    if [ -z "$cluster_node_id" ]; then
        echo Skipping pre-stop as no cluster_node_id.
        exit 0
    fi

    setAndWaitForStatus "DISCONNECTING" "DISCONNECTED"
    setAndWaitForStatus "OFFLOADING" "OFFLOADED"

    echo Removing cluster node $cluster_node_id
    curl -s -X DELETE http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id
    echo Removed cluster node $cluster_node_id
) | tee -a ${logfile}