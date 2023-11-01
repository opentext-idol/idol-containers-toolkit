# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

{{/* Generate distributed-idol deployment liveness probe timeouts */}}
{{- define "singlecontent.deployment.standardLivenessProbe" }}
          initialDelaySeconds: 8
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{/* Standard labels */}}
{{- define "singlecontent.labels" }}
{{- include "idol-library.labels" . }}
{{- end }}

