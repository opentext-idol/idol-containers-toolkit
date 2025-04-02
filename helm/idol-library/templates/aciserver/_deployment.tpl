# BEGIN COPYRIGHT NOTICE
# Copyright 2023-2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{- define "idol-library.aciserver.deployment.base.v1" -}}
{{/*
    Common template for a generic ACI server deployment
*/}}
{{ $ctx := . }}
{{ $root := get . "root" | required "missing root" }}
{{ $component := get . "component" | required "missing component" }}
{{ $env := get . "env" | default list }}
{{ $volumes := get . "volumes" | default list }}
{{ $volumeMounts := get . "volumeMounts" | default list }}
{{ $containers := get . "containers" | default (list "idol-library.aciserver.container.base.v1") }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $component.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
spec:
  # workaround dig not working with .Values
  replicas: {{ dig "replicas" 1 (unset $component "") | int }}
  selector:
    matchLabels:
      app: {{ $component.name | quote }}
  template:
    metadata:
      labels: {{- include "idol-library.labels" . | nindent 8 }}
        app: {{ $component.name | quote }}
      {{- if $component.annotations }}
      annotations:
        {{- with $component.annotations }}
        {{- toYaml . | trim | nindent 8 }}
        {{- end }}
      {{- end }}
    spec:
      {{- if $component.serviceAccountName }}
      serviceAccountName: {{ $component.serviceAccountName }}
      {{- end }}
      imagePullSecrets:
      {{- range $root.Values.global.imagePullSecrets }}
      - name: {{ . }}
      {{- end }}
      containers:
      {{- range $containers }}
      - {{ include . $ctx | nindent 8 }}
      {{- end }}
      volumes:
      - name: config-map
        configMap:
          name: {{ default (printf "%s-default-cfg" $component.name) $component.existingConfigMap }}
      {{- if $root.Values.global.idolOemLicenseSecret }}
      - name: oem-license
        secret:
          secretName: {{ $root.Values.global.idolOemLicenseSecret }}
      {{- end }}
      {{- range $volumes }}
      - {{ . | toYaml | nindent 8 }}
      {{- end }}
      {{- include "idol-library.util.range_array_or_map_values" (dict "root" $root "vals" $component.additionalVolumes) | indent 6 }}
      {{- if (dig "podSecurityContext" "enabled" false ($component | merge (dict))) }}
      securityContext: {{- omit $component.podSecurityContext "enabled" | toYaml | nindent 8 }}
      {{- end }}
{{- end -}}

{{/*
Generates deployment for an ACI Server
@param .root The root context
@param .component The component values
@param .destination Template to merge onto
See also "idol-library.aciserver.defaultcfg"
*/}}
{{- define "idol-library.aciserver.deployment" -}}
{{- $root := get . "root" | required "missing root" -}}
{{- $component := get . "component" | required "missing component" -}}
{{- $_ := set . "source" "idol-library.aciserver.deployment.base.v1" -}}
{{- include "idol-library.util.merge" $_ -}}
{{- end -}}