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

host=`curl -s http://$NIFI_WEB_HTTP_HOST:$NIFI_WEB_HTTP_PORT/nifi-api/controller/cluster | jq -r ".cluster.nodes[] | select(any(.roles[]; . == \"Primary Node\")) | .address "`
port=$NIFI_WEB_HTTP_PORT
cluster_node_id=`curl -s http://$NIFI_WEB_HTTP_HOST:$NIFI_WEB_HTTP_PORT/nifi-api/controller/cluster | jq -r ".cluster.nodes[] | select(.address==\"$NIFI_WEB_HTTP_HOST\") | .nodeId "`

setAndWaitForStatus () {
    curl -s -X PUT http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id -H 'Content-Type: application/json' -d "{\"node\":{\"nodeId\":\"$cluster_node_id\",\"status\": \"$1\"}}"
    cluster_node_status="$1"
    while [ "$cluster_node_status" != "$2" ]
    do
        sleep 1
        cluster_node_status=`curl -s http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id | jq .node.status -r`
    done
}

if [ ! -z "$cluster_node_id" ]
then
    setAndWaitForStatus "DISCONNECTING" "DISCONNECTED"
    setAndWaitForStatus "OFFLOADING" "OFFLOADED"
    curl -s -X DELETE http://$host:$port/nifi-api/controller/cluster/nodes/$cluster_node_id
fi