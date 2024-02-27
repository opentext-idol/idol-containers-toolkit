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

{{- define "idol-library.aciserver.statefulset.base.v1" -}}
{{/*
    Common template for a generic ACI server statefulset
*/}}
{{ $ctx := . }}
{{ $root := get . "root" | required "idol-library.aciserver.statefulset.base.v1: missing root" }}
{{ $component := get . "component" | required "idol-library.aciserver.statefulset.base.v1: missing component" }}
{{ $volumes := get . "volumes" | default list }}
{{ $containers := get . "containers" | default (list "idol-library.aciserver.container.base.v1") }}
{{ $addConfigMap := dig "addConfigMap" true . }}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $component.name | quote }}
  labels: {{- include "idol-library.labels" $ctx | nindent 4 }}
spec:
  serviceName: {{ $component.name | quote }}
  replicas: 1
  selector:
    matchLabels:
      app: {{ $component.name | quote }}
  template:
    metadata:
      labels: {{- include "idol-library.labels" $ctx | nindent 8 }}
        app: {{ $component.name | quote }}
    spec:
      imagePullSecrets:
      {{- range $root.Values.global.imagePullSecrets }}
      - name: {{ . }}
      {{- end }}
      containers:
      {{- range $containers }}
      - {{ include . $ctx | nindent 8 }}
      {{- end }}
      volumes:
      {{- if $addConfigMap }}
      - name: config-map
        configMap:
          name: {{ default (printf "%s-default-cfg" $component.name) $component.existingConfigMap }}
      {{- end }}
      {{- range $volumes }}
      - {{ . | toYaml | nindent 8 }}
      {{- end }}
      {{- range $component.additionalVolumes }}
      - {{ . | toYaml | nindent 8 }}
      {{- end }}
      {{- if $component.podSecurityContext.enabled }}
      securityContext: {{- omit $component.podSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}

{{- end -}}