# BEGIN COPYRIGHT NOTICE
# Copyright 2025 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{/* Generates merged yaml representing a single nifi cluster
@param .root The root context
@param .item A single entry from Values.nifiClusters[]
*/}}
{{- define "idolnifi.clusterItem" }}
{{- $root := get . "root" | required "idolnifi.clusterItem: missing root"}}
{{- $item := get . "item" | required "idolnifi.clusterItem: missing item"}}
{{- $mergedItem := mergeOverwrite (dict) 
        (dict "clusterId" $root.Values.name 
              "image" $root.Values.idolImage)
        (deepCopy $root.Values )
        (deepCopy $root.Values.nifi )
        (dict "name" (default $root.Values.name $item.clusterId)) 
        $item }} 
{{ toYaml $mergedItem }}
{{- end }}
