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

{{- define "idolomnigroupserver.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolomnigroupserver.container.base: missing root" -}}
{{- $component := get . "component" | required "idolomnigroupserver.container.base: missing component" -}}
{{- /* END of idolomnigroupserver.container.base */ -}}
{{- end -}}

{{- define "idolomnigroupserver.container" -}}
{{- $root := get . "root" | required "idolomnigroupserver.container: missing root" -}}
{{- $component := get . "component" | required "idolomnigroupserver.container: missing component" -}}
{{- $env := list }}
{{- $volumeMounts := (list (dict "name" "index" "mountPath" "/omnigroupserver/DBs") 
      (dict "name" "oauth-prestart-scripts" "mountPath" "/omnigroupserver/prestart_scripts" "readOnly" true)) }}
{{- if $component.oauthToolConfigMap }}
{{- $env = append $env (dict "name" "OAUTH_TOOL_CFG" "value" "/etc/config/oauth/oauth_tool.cfg")}}
{{- $volumeMounts = concat $volumeMounts (list (dict "name" "oauth-tool-config-file" "mountPath" "/etc/config/oauth" "readOnly" true)) }}
{{- end }}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolomnigroupserver.container.base" 
  "env" $env
  "volumeMounts" $volumeMounts
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}