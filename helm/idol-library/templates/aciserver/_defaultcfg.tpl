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
{{/*
Generates the configmap containing default configuration file for an ACI Server
See "idol-library.aciserver.deployment"
Assumes config file exists in resources/ directory

@param .root The root context
@param .component The component values
@param .componentName Base name for the config file
*/}}
{{- define "idol-library.aciserver.defaultcfg" -}}
{{- $root := get . "root" | required "root" -}}
{{- $component := get . "component" | required "component" -}}
{{- $componentName := get . "componentName" | required "componentName" -}}
{{- if not $component.existingConfigMap }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ $component.name }}-default-cfg
  labels: {{- include "idol-library.labels" . | nindent 4 }}
data:
  {{ $componentName }}.cfg: |
{{ tpl (print "resources/" $componentName ".cfg" | $root.Files.Get) $root | indent 4 }}
{{- end -}}
{{- end -}}