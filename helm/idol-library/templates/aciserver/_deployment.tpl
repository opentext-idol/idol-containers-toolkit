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

{{- define "idol-library.aciserver.deployment.base" -}}
{{/*
    Common template for a generic ACI server deployment
*/}}
{{ $root := get . "root" | required "missing root" }}
{{ $component := get . "component" | required "missing component" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $component.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ $component.name | quote }}
  template:
    metadata:
      labels: {{- include "idol-library.labels" . | nindent 8 }}
        app: {{ $component.name | quote }}
    spec:
      imagePullSecrets:
        {{- range $root.Values.global.imagePullSecrets }}
        - name: {{ . }}
        {{- end }}
      containers:
      - name: {{ $component.name | quote }}
        image: {{ include "idol-library.idolImage" (dict "root" $root "idolImage" $component.idolImage) }}
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /a=getpid
            port: {{ $component.aciPort | int }}
{{- template "idol-library.standardLivenessProbe" $component.livenessProbe }}
        ports:
        - containerPort: {{ $component.aciPort | int }}
          name: aci-port
          protocol: TCP
        - containerPort: {{ $component.servicePort | int }}
          name: service-port
          protocol: TCP
        volumeMounts:
        - name: config-map
          mountPath: /etc/config/idol
        {{- range $component.additionalVolumeMounts }}
        - {{ . | toYaml | nindent 10 }}
        {{- end }}
        env:
        - name: IDOL_COMPONENT_CFG
          value: {{ printf "/etc/config/idol/%s.cfg" (trimPrefix "idol-" $component.name) }}
        - name: OAUTH_TOOL_CFG
          value: /etc/config/idol/oauth_tool.cfg
        {{- if $component.envConfigMap }}
        envFrom:
        - configMapRef: {{ $component.envConfigMap | quote }}
        {{ end }}
      volumes:
      - name: config-map
        configMap:
          name: {{ default (printf "%s-default-cfg" $component.name) $component.existingConfigMap }}
      {{- range $component.additionalVolumes }}
      - {{ . | toYaml | nindent 8 }}
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
{{- $_ := set . "source" "idol-library.aciserver.deployment.base" -}}
{{- include "idol-library.util.merge" $_ -}}
{{- end -}}