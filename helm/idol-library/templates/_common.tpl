{{/* Standard labels */}}
{{- define "idol-library.labels" -}}
app.kubernetes.io/name: {{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ with .Values.labels }}
{{- toYaml . | trim }}
{{- end }}
{{- end }}


{{/* Allow the release namespace to be overridden for multi-namespace deployments in combined charts */}}
{{- define "idol-library.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}
