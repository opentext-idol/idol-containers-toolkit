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

{{/* Generate idol-find deployment liveness probe timeouts */}}
{{- define "idolfind.deployment.standardLivenessProbe" }}
          initialDelaySeconds: {{ .initialDelaySeconds | default 8 | int }}
          timeoutSeconds: {{ .timeoutSeconds | default 3 | int }}
          periodSeconds: {{ .periodSeconds | default 10 | int }}
          failureThreshold: {{ .failureThreshold | default 3 | int }}
{{- end -}}

{{/* Standard labels */}}
{{- define "idolfind.labels" }}
{{- include "idol-library.labels" . }}
{{- end }}

