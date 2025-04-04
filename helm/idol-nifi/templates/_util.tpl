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

{{/* Calls a named template for each nifi cluster defined in .Values.nifiClusters
@param .root The root context
@param .tpl The name of the template to include
The template will be called with a copy of the same args plus:
 nifiCluster: the merged object for this cluster instance
 nifiClustersLen: the number of clusters total
*/}}
{{- define "idolnifi.forEachCluster" }}
{{- $root := get . "root" | required "idolnifi.forEachCluster: missing root" }}
{{- $tpl := get . "tpl" | required "idolnifi.forEachCluster: missing tpl" }}
{{- range $nifiClusterItem := default (list dict) 
      (include "idol-library.util.range_array_or_map_values" (dict "root" $root "vals" $root.Values.nifiClusters) | fromYamlArray) }}
{{ $nifiCluster := (include "idolnifi.clusterItem" (dict "root" $.root "item" $nifiClusterItem) | fromYaml) }}
{{ $args := merge (dict "nifiCluster" $nifiCluster 
                        "nifiClustersLen" (default (list dict) ($.root.Values.nifiClusters) | len ))
                  ($) }}
{{ include $.tpl $args }}
{{- end }}
{{- end }}
