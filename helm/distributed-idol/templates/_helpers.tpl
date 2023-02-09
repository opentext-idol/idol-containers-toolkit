{{/* Generate distributed-idol deployment liveness probe timeouts */}}
{{- define "distributedidol.deployment.standardLivenessProbe" }}
          initialDelaySeconds: 8
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{/* Standard labels */}}
{{- define "distributedidol.labels" }}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}
