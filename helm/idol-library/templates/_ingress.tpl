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
{{- $root := get . "root" | required "missing root" -}}
{{- $component := get . "component" | required "missing component" -}}
{{- $ingress := get . "ingress" | required "missing ingress" -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ $component.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
  annotations:
{{- if eq $ingress.type "nginx" }}
    nginx.ingress.kubernetes.io/rewrite-target: /$1
  {{- if $ingress.proxyBodySize }}
    nginx.ingress.kubernetes.io/proxy-body-size: {{ $ingress.proxyBodySize }}
  {{- end -}}
{{- else if eq $ingress.type "haproxy" }}
    haproxy.router.openshift.io/rewrite-target: / 
  {{- if $ingress.proxyBodySize }}
    haproxy.router.openshift.io/proxy-body-size: {{ $ingress.proxyBodySize }}
  {{- end -}}
{{- end }}
spec:
{{- if $ingress.className }}
  ingressClassName: {{ $ingress.className }}
{{- end }}
  rules:
  - http:
{{- if $ingress.host }}
    host: {{ $ingress.host }}
{{- end }}
{{- end }}


{{/*
Generates ingress
@param .root The root context
@param .component The component values
@param .ingress The ingress specific values
@param .destination Template to merge onto
*/}}
{{- define "idol-library.ingress" -}}
{{- $root := get . "root" | required "missing root" -}}
{{- $component := get . "component" | required "missing component" -}}
{{- $ingress := get . "ingress" | required "missing ingress" -}}
{{- if $ingress.enabled }}
{{- $_ := set . "source" "idol-library.ingress.base" -}}
{{- include "idol-library.util.merge" $_ -}}
{{- end -}}
{{- end -}}


{{- /*
 nginx ingress needs path capture to achieve prefix type routing
*/}}
{{- define "idol-library.ingress.pathsuffix" -}}
{{- $ingress := get . "ingress" | required "missing ingress" -}}
{{ eq $ingress.type "nginx" | ternary "(.*)" "" }}
{{- end -}}

{{- define "idol-library.ingress.pathtype" -}}
{{- $ingress := get . "ingress" | required "missing ingress" -}}
{{- eq $ingress.type "nginx" | ternary "ImplementationSpecific" "Prefix" -}}
{{- end -}}

{{/* Modifies path value appropriate to ingress type
@param .ingress The ingress values
@param .path The base path to be modified
*/}}
{{- define "idol-library.ingress.path" -}}
{{- $ingress := get . "ingress" | required "missing ingress" -}}
{{- $path := get . "path" | required "missing path" -}}
{{ include "idol-library.ingress.pathsuffix" . | print $path }}
{{- end -}}
