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

{{- define "idolacitest.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolacitest.container.base: missing root" -}}
{{- $component := get . "component" | required "idolacitest.container.base: missing component" -}}
os:
  name: linux
{{- /* END of idolacitest.container.base */ -}}
{{- end -}}

{{- define "idolacitest.container" -}}
{{- $root := get . "root" | required "idolacitest.container: missing root" -}}
{{- $component := get . "component" | required "idolacitest.container: missing component" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolacitest.container.base" 
  "volumeMounts" (list (dict "name" "testVolMount" "mountPath" "/test/volume/mount"))
  "ports" (list (dict "containerPort" 12345 "name" "test-port" "protocol" "TCP"))
  "env" (list (dict "name" "IDOL_CONTENT_SERVICE_PORT_ACI_PORT" "value" ($component.aciPort | quote))
              (dict "name" "IDOL_COMMAND_PARAMS" "value" "-idolcluster"))
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}