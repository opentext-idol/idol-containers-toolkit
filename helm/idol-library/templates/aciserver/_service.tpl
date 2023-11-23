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
{{- define "idol-library.aciserver.service.base" -}}
{{/*
    Common template for a generic ACI server service
*/}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.name | quote }}
  labels: {{- include "idol-library.labels" . | nindent 4 }}
spec:
  ports:
  - port: {{ .Values.aciPort | int }}
    targetPort: aci-port
    name: aci-port
  - port: {{ .Values.servicePort | int }}
    targetPort: service-port
    name: service-port
  selector:
    app: {{ .Values.name | quote }}
{{- end -}}

{{/*
Generates Service for an ACI Server
Takes:
- top context
- template to merge into deployment base
*/}}
{{- define "idol-library.aciserver.service" -}}
{{- include "idol-library.util.merge" (append . "idol-library.aciserver.service.base") -}}
{{- end -}}