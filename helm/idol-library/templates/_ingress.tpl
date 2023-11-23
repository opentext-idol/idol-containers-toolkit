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
{{- define "idol-library.ingress.base" -}}
{{/*
    Common ingress template
*/}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .Values.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
  annotations:
{{- if eq .Values.ingressType "nginx" }}
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  {{- if .Values.ingressProxyBodySize }}
    nginx.ingress.kubernetes.io/proxy-body-size: {{ .Values.ingressProxyBodySize }}
  {{- end -}}
{{- else if eq .Values.ingressType "haproxy" }}
    haproxy.router.openshift.io/rewrite-target: / 
  {{- if .Values.ingressProxyBodySize }}
    haproxy.router.openshift.io/proxy-body-size: {{ .Values.ingressProxyBodySize }}
  {{- end -}}
{{- end }}
spec:
{{- if .Values.ingressClassName }}
  ingressClassName: {{ .Values.ingressClassName }}
{{- end }}
  rules:
  - http:
{{- if .Values.ingressHost }}
    host: {{ .Values.ingressHost }}
{{- end }}
{{- end }}


{{/*
Generates ingress
Takes:
- top context
- template to merge into deployment base
*/}}
{{- define "idol-library.ingress" -}}
{{- if .Values.ingressEnabled }}
{{- include "idol-library.util.merge" (append . "idol-library.ingress.base") -}}
{{- end -}}
{{- end -}}


{{- /*
 nginx ingress needs path capture to achieve prefix type routing
*/}}
{{- define "idol-library.ingress.pathsuffix" -}}
{{ eq .Values.ingressType "nginx" | ternary "(.*)" "" }}
{{- end -}}

{{- define "idol-library.ingress.pathtype" -}}
{{- eq .Values.ingressType "nginx" | ternary "ImplementationSpecific" "Prefix" -}}
{{- end -}}

{{/* 
Takes 
- top context
- path string
*/}}
{{- define "idol-library.ingress.path" -}}
{{ include "idol-library.ingress.pathsuffix" (first .) | print (last .) }}
{{- end -}}
