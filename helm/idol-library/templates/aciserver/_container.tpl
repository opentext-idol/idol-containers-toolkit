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
{{- $mountConfigMap := dig "mountConfigMap" true . -}}
name: {{ $component.name | quote }}
image: {{ include "idol-library.idolImage" (dict "root" $root "idolImage" $component.idolImage) }}
imagePullPolicy: {{ default (default "IfNotPresent" $component.idolImage.imagePullPolicy) $component.global.imagePullPolicy | quote }}
{{- if $component.aciPort }}
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
{{- end }}
{{- range $ports }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
volumeMounts:
{{- if $mountConfigMap }}
- name: config-map
  mountPath: /etc/config/idol
{{- end }}
{{- range $volumeMounts }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
{{- range $component.additionalVolumeMounts }}
- {{ . | toYaml | nindent 10 }}
{{- end }}
{{- if $root.Values.global.idolOemLicenseSecret }}
- name: oem-license
  mountPath: {{ printf "/%s/licensekey.dat" (trimPrefix "idol-" $component.name) }}
  subPath: licensekey.dat
  readOnly: true
- name: oem-license
  mountPath: {{ printf "/%s/versionkey.dat" (trimPrefix "idol-" $component.name) }}
  subPath: versionkey.dat
  readOnly: true
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
{{- end }}
{{- if $component.envConfigMap }}
envFrom:
- configMapRef: 
    name: {{ $component.envConfigMap | quote }}
{{ end }}
{{- if (dig "containerSecurityContext" "enabled" false $component.AsMap) }}
securityContext: {{- omit $component.containerSecurityContext "enabled" | toYaml | nindent 10 }}
{{- end }}
{{- if (dig "resources" "enabled" false $component.AsMap) }}
resources: {{- omit $component.resources "enabled" | toYaml | nindent 10 }}
{{- end }}

{{- end -}}