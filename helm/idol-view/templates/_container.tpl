# BEGIN COPYRIGHT NOTICE
# Copyright 2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{- define "idolviewserver.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolviewserver.container.base: missing root" -}}
{{- $component := get . "component" | required "idolviewserver.container.base: missing component" -}}
{{- /* END of idolviewserver.container.base */ -}}
{{- end -}}

{{- define "idolviewserver.container" -}}
{{- $root := get . "root" | required "idolviewserver.container: missing root" -}}
{{- $component := get . "component" | required "idolviewserver.container: missing component" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolviewserver.container.base" 
) -}}
{{- /* END of idolacitest.container */ -}}
{{- end -}}