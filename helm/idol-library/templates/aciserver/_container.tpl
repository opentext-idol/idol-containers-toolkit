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

{{- define "idol-library.aciserver.container.base.v1" -}}
{{/* 
  Common template for generic ACI server container
*/}}
{{- $root := get . "root" | required "idol-library.aciserver.container.base.v1: missing root" -}}
{{- $component := get . "component" | required "idol-library.aciserver.container.base.v1: missing component" -}}
{{- $env := get . "env" | default list -}}
{{- $volumeMounts := get . "volumeMounts" | default list -}}
{{- $ports := get . "ports" | default list -}}
name: {{ $component.name | quote }}
image: {{ include "idol-library.idolImage" (dict "root" $root "idolImage" $component.idolImage) }}
imagePullPolicy:
{{- if and $component.global.imagePullPolicy (ne $component.global.imagePullPolicy "") }}
  {{- $component.global.imagePullPolicy | quote | nindent 2 -}}
{{- else if $component.idolImage.imagePullPolicy }}
  {{- $component.idolImage.imagePullPolicy | quote | nindent 2 -}}
{{- else }}
  {{- "IfNotPresent" | nindent 2 -}}
{{- end }}
livenessProbe:
  httpGet:
    path: /a=getpid
    port: {{ $component.aciPort | int }}
    scheme: {{ $component.usingTLS | ternary "HTTPS" "HTTP" }}
{{- include "idol-library.standardLivenessProbe" $component.livenessProbe | fromYaml | toYaml | nindent 2}}
ports:
- containerPort: {{ $component.aciPort | int }}
  name: aci-port
  protocol: TCP
- containerPort: {{ $component.servicePort | int }}
  name: service-port
  protocol: TCP
{{- if $component.indexPort }}
- containerPort: {{ $component.indexPort | int }}
  name: index-port
  protocol: TCP
{{- end }}
{{- range $ports }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
volumeMounts:
- name: config-map
  mountPath: /etc/config/idol
{{- range $volumeMounts }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
{{- range $component.additionalVolumeMounts }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
env:
- name: IDOL_COMPONENT_CFG
  value: {{ printf "/etc/config/idol/%s.cfg" (trimPrefix "idol-" $component.name) }}
{{- range $env }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
{{- if $component.usingTLS -}}
- name: IDOL_SSL
  value: "1"
{{- end -}}
{{- if $component.envConfigMap }}
envFrom:
- configMapRef: 
    name: {{ $component.envConfigMap | quote }}
{{ end }}
{{- if $component.containerSecurityContext.enabled }}
securityContext: {{- omit $component.containerSecurityContext "enabled" | toYaml | nindent 10 }}
{{- end }}

{{- end -}}