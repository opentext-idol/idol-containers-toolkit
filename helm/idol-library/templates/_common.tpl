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
@param .omit_chart_version Include chart version in labels?
*/}}
{{- define "idol-library.labels" -}}
{{- $root := get . "root" | required "idol-library.labels: missing root" -}}
{{- $component := get . "component" | required "idol-library.labels: missing component" -}}
{{- $omit_chart_version := default false .omit_chart_version -}}
app.kubernetes.io/name: {{ default $root.Chart.Name $component.nameOverride | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
{{- if not $omit_chart_version}}
helm.sh/chart: {{ printf "%s-%s" $root.Chart.Name $root.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}
{{ with $component.labels }}
{{- toYaml . | trim }}
{{- end }}
{{- end }}

{{/* volumeClaimTemplates in StatefulSets must not be modified during upgrade
so don't include the chart version
see https://github.com/kubernetes/enhancements/issues/4650
*/}}
{{- define "idol-library.labels.volumeClaimTemplates" -}}
{{- $ctx := . -}}
{{ include "idol-library.labels" (dict
    "root" $ctx.root
    "component" $ctx.component
    "omit_chart_version" true)
}}
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
{{ print (default $idolImage.registry (dig "global" "idolImageRegistry" "" $root.Values.AsMap))
                      "/"  $idolImage.repo  ":" 
                      (default $idolImage.version (dig "global" "idolVersion" "" $root.Values.AsMap)) }}
{{- end -}}
