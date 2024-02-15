# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{- define "idolcommunity.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolcommunity.container.base: missing root" -}}
{{- $component := get . "component" | required "idolcommunity.container.base: missing component" -}}
{{- /* END of idolcommunity.container.base */ -}}
{{- end -}}

{{- define "idolcommunity.container" -}}
{{- $root := get . "root" | required "idolcommunity.container: missing root" -}}
{{- $component := get . "component" | required "idolcommunity.container: missing component" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolcommunity.container.base" 
  "env" (list (dict "name" "IDOL_CONTENT_HOST"        "value" $component.queryserviceName)
              (dict "name" "IDOL_CONTENT_ACI_PORT"    "value" $component.queryserviceACIPort)
              (dict "name" "IDOL_AGENTSTORE_HOST"     "value" $component.agentStoreName)
              (dict "name" "IDOL_AGENTSTORE_ACI_PORT" "value" $component.agentStoreACIPort)
              )
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}