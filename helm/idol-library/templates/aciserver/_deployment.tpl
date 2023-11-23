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
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Values.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {{ .Values.name | quote }}
  template:
    metadata:
      labels: {{- include "idol-library.labels" . | nindent 8 }}
        app: {{ .Values.name | quote }}
    spec:
      imagePullSecrets:
        {{- range .Values.imagePullSecrets }}
        - name: {{ . }}
        {{- end }}
      containers:
      - name: {{ .Values.name | quote }}
        image: {{ .Values.idolImageRegistry }}/{{ .Values.image }}:{{ .Values.idolVersion }}
        imagePullPolicy: IfNotPresent
        livenessProbe:
          httpGet:
            path: /a=getpid
            port: {{ .Values.aciPort | int }}
{{- template "idol-library.standardLivenessProbe" .Values.livenessProbe }}
        ports:
        - containerPort: {{ .Values.aciPort | int }}
          name: aci-port
          protocol: TCP
        - containerPort: {{ .Values.servicePort | int }}
          name: service-port
          protocol: TCP
        volumeMounts:
        - name: config-map
          mountPath: /etc/config/idol
        {{- range .Values.additionalVolumeMounts }}
        - {{ . | toYaml | nindent 10 }}
        {{- end }}
        env:
        - name: IDOL_COMPONENT_CFG
          value: {{ printf "/etc/config/idol/%s.cfg" (trimPrefix "idol-" .Values.name) }}
      volumes:
      - name: config-map
        configMap:
          name: {{ default (printf "%s-default-cfg" .Values.name) .Values.existingConfigMap }}
      {{- range .Values.additionalVolumes }}
      - {{ . | toYaml | nindent 8 }}
      {{- end }}
{{- end -}}

{{/*
Generates deployment for an ACI Server
Takes:
- top context
- template to merge into deployment base
See also "idol-library.aciserver.defaultcfg"
*/}}
{{- define "idol-library.aciserver.deployment" -}}
{{- include "idol-library.util.merge" (append . "idol-library.aciserver.deployment.base") -}}
{{- end -}}