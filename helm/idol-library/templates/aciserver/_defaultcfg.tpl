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
*/}}
{{- define "idol-library.aciserver.defaultcfg" -}}
{{- if not .Values.existingConfigMap }}
{{- $componentName := trimPrefix "idol-" .Values.name }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Values.name }}-default-cfg
  labels: {{- include "idol-library.labels" . | nindent 4 }}
data:
  {{ $componentName }}.cfg: |
{{ tpl (print "resources/" $componentName ".cfg" | .Files.Get) . | indent 4 }}
{{- end -}}
{{- end -}}