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

{{- define "singlecontent.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "singlecontent.container.base: missing root" -}}
{{- $component := get . "component" | required "singlecontent.container.base: missing component" -}}
command:
  - "/bin/bash"
args: 
  - "-c"
  - |
{{ tpl ($root.Files.Get "resources/content_startup.sh") $root | indent 4 }}

lifecycle:
  postStart:
    exec:
      command:
      - /bin/bash
      - "-c"
      - |
{{ tpl ($root.Files.Get "resources/content_postStart.sh") $root | indent 8 }}

{{- /* END of idolacitest.container.base */ -}}
{{- end -}}

{{- define "singlecontent.container" -}}
{{- $root := get . "root" | required "singlecontent.container: missing root" -}}
{{- $component := get . "component" | required "singlecontent.container: missing component" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "singlecontent.container.base" 
  "env" (list (dict "name" "IDOL_CONTENT_SERVICE_PORT_ACI_PORT" "value" ($component.aciPort))
              (dict "name" "IDOL_COMMAND_PARAMS" "value" "-idolcluster"))
  "volumeMounts" (list (dict "name" "index" "mountPath" "/opt/idol/content/index"))
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}