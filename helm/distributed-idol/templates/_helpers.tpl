{{/* Generate distributed-idol deployment liveness probe timeouts */}}
{{- define "distributedidol.deployment.standardLivenessProbe" }}
          initialDelaySeconds: 8
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{/* Standard labels */}}
{{- define "distributedidol.labels" }}
{{- include "idol-library.labels" . }}
{{- end }}

