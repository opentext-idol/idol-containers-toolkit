# BEGIN COPYRIGHT NOTICE
# (c) Copyright 2023 Micro Focus or one of its affiliates.
# END COPYRIGHT NOTICE

{{/* Standard labels */}}
{{- define "singlecontent.labels" }}
{{- include "idol-library.labels" (dict "root" . "component" .Values) }}
{{- end }}

