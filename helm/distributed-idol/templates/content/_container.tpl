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

{{- define "didolcontent.container.base" -}}
{{- $root := get . "root" | required "didolcontent.container.base: missing root" -}}
command:
- "/bin/bash"
args:
- "-c"
- |
{{ tpl ($root.Files.Get "resources/content_startup.sh") $root | indent 10 }}
lifecycle:
  postStart:
    exec:
      command:
      - /bin/bash
      - "-c"
      - |
{{ tpl ($root.Files.Get "resources/content_postStart.sh") $root | indent 16 }}
  preStop:
    exec:
      command:
      - /bin/bash
      - "-c"
      - |
{{ tpl ($root.Files.Get "resources/content_preStop.sh") $root | indent 16 }}
{{- end -}}

{{- define "didolcontent.container" -}}
{{- $root := get . "root" | required "didolcontent.container: missing root" -}}
{{- $component := get . "component" | required "didolcontent.container: missing component" -}}

{{- $contentVolumeMounts := list (dict "name" "index" "mountPath" "/opt/idol/content/index") }}
{{- if $root.Values.setupMirrored }}
{{- $contentVolumeMounts = append $contentVolumeMounts (dict
  "name" "archive-share"
  "mountPath" "/opt/idol/archive"
) }}
{{- end }}

{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "didolcontent.container.base"
  "env" (list (dict "name" "IDOL_CONTENT_SERVICE_PORT_ACI_PORT" "value" ($component.aciPort))
              (dict "name" "IDOL_COMMAND_PARAMS" "value" "-idolcluster"))
  "volumeMounts" $contentVolumeMounts
) -}}
{{- end -}}