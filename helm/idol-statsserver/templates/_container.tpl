# BEGIN COPYRIGHT NOTICE
# Copyright 2026 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{- define "idolstatsserver.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolstatsserver.container.base: missing root" -}}
{{- $component := get . "component" | required "idolstatsserver.container.base: missing component" -}}
{{- /* END of idolstatsserver.container.base */ -}}
{{- end -}}

{{- define "idolstatsserver.container" -}}
{{- $root := get . "root" | required "idolstatsserver.container: missing root" -}}
{{- $component := get . "component" | required "idolstatsserver.container: missing component" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolstatsserver.container.base" 
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}