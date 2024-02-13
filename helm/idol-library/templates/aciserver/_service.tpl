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
{{- define "idol-library.aciserver.service.base" -}}
{{/*
    Common template for a generic ACI server service
*/}}
{{- $root := get . "root" | required "idol-library.aciserver.service.base: missing root" -}}
{{- $component := get . "component" | required "idol-library.aciserver.service.base: missing component" -}}
{{- $ports := get . "ports" | default list -}} 
apiVersion: v1
kind: Service
metadata:
  name: {{ $component.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
spec:
  ports:
  - port: {{ $component.aciPort | int }}
    targetPort: aci-port
    name: aci-port
  - port: {{ $component.servicePort | int }}
    targetPort: service-port
    name: service-port
  {{ if $component.indexPort }}
  - port: {{ $component.indexPort | int }}
    targetPort: index-port
    name: index-port
  {{ end }}
  {{- range $ports }}
  - {{ . | toYaml | nindent 4 }}
  {{- end }}
  selector:
    app: {{ $component.name | quote }}
{{- end -}}

{{/*
Generates Service for an ACI Server
@param .root The root context
@param .component The component values
@param .destination Template to merge onto
*/}}
{{- define "idol-library.aciserver.service" -}}
{{- $root := get . "root" | required "missing root" -}}
{{- $component := get . "component" | required "missing component" -}}
{{- $_ := set . "source" "idol-library.aciserver.service.base" -}}
{{- include "idol-library.util.merge" $_ -}}
{{- end -}}