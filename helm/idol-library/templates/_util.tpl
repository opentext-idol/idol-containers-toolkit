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
{{- /*
idol-library.util.merge will merge two YAML templates and output the result.
See https://helm.sh/docs/chart_template_guide/function_list/#merge-mustmerge

@param .root The root context
@param .component Component values 
@param .destination Destination template (these values take precedence)
@param .source Source template

*/ -}}
{{- define "idol-library.util.merge" -}}
{{- $root := get . "root" | required "idol-library.util.merge: missing root" -}}
{{- $component := get . "component" | required "idol-library.util.merge: missing component" -}}
{{- $dest := get . "destination" | required "idol-library.util.merge: missing destination" -}}
{{- $src := get . "source" | required "idol-library.util.merge: missing source" -}}
{{- $overrides := fromYaml (include $dest .) | default (dict ) -}}
{{- $tpl := fromYaml (include $src .) | default (dict ) -}}
{{- toYaml (merge $overrides $tpl) -}}
{{- end -}}

{{- /*
idol-library.util.range_array_or_map_values will take either an array or a map
and converts (if necessary) to a yaml array
Motivation for this is that yaml merging will merge maps but 
overwrite arrays. In some cases (e.g. additonalVolumes, additionalVolumeMounts)
it's useful to want to be able to extend a 'list' of volumes and
we can allow this by converting to map with key names that are ignored (or merged on)
*/ -}}
{{- define "idol-library.util.range_array_or_map_values" -}}
{{- $root := get . "root" | required "idol-library.util.range_array_or_map_values: missing root" -}}
{{- $vals := get . "vals" | default list -}}
{{- if kindIs (kindOf list ) $vals }}
{{- range $v := $vals  }}
- {{ $v | toYaml | nindent 2 }}
{{- end }}
{{- else }}
{{- /* note that keys are dropped, and an item with DELETE: true is omitted */ -}}
{{- range $k,$v := $vals }}
{{- if (or 
    (kindIs (kindOf "") $v)
    (kindIs (kindOf list) $v)
    (and (kindIs (kindOf dict) $v) (gt (len $v) 0) (not (get $v "DELETE"))) 
) }}
- {{ $v | toYaml | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
