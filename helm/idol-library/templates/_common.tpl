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

{{/* Standard labels 
@param .root The root context
@param .component The component values
*/}}
{{- define "idol-library.labels" -}}
{{- $root := get . "root" | required "idol-library.labels: missing root" -}}
{{- $component := get . "component" | required "idol-library.labels: missing component" -}}
app.kubernetes.io/name: {{ default $root.Chart.Name $component.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
helm.sh/chart: {{ printf "%s-%s" $root.Chart.Name $root.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ with $component.labels }}
{{- toYaml . | trim }}
{{- end }}
{{- end }}


{{/* Generate standard IDOL deployment liveness probe timeouts */}}
{{- define "idol-library.standardLivenessProbe" }}
          initialDelaySeconds: {{ .initialDelaySeconds | default 8 | int }}
          timeoutSeconds: {{ .timeoutSeconds | default 3 | int }}
          periodSeconds: {{ .periodSeconds | default 10 | int }}
          failureThreshold: {{ .failureThreshold | default 3 | int }}
{{- end -}}


{{/* Allow the release namespace to be overridden for multi-namespace deployments in combined charts */}}
{{- define "idol-library.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}


{{/* Combines values to form container image name
@param .root The root context (for accessing global overrides)
@param .idolImage The idolImage values
*/}}
{{- define "idol-library.idolImage" -}}
{{- $root := get . "root" | required "idol-library.idolImage: missing root" -}}
{{- $idolImage := get . "idolImage" | required "idol-library.idolImage: missing idolImage" -}}
{{ print (default $idolImage.registry (dig "global" "idolImageRegistry" "" ($root.Values | merge dict )))
                      "/"  $idolImage.repo  ":" 
                      (default $idolImage.version (dig "global" "idolVersion" "" ($root.Values | merge dict ))) }}
{{- end -}}
