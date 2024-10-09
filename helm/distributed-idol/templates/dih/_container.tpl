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

{{- define "distributedidol.dih.container.base" -}}
{{- $root := get . "root" | required "distributedidol.dih.container.base: missing root" -}}
{{- $component := get . "component" | required "distributedidol.dih.container.base: missing component" -}}
{{/* specific merges to container specification */}}
command: ["/bin/sh"]
args:
  - -c
  - |
    cd /dih
    ln -sf /opt/idol/dih/data ./data
    if [ -e /opt/idol/dih/data/dih.cfg ]
    then
      echo Using existing dih.cfg
    else
      cp /opt/idol/dih/data/dih.install.cfg /opt/idol/dih/data/dih.cfg
    fi
    ln -sf /opt/idol/dih/data/dih.cfg ./dih.cfg
    ./run_idol.sh
lifecycle:
  preStop:
    exec:
      command:
        - /bin/bash
        - "-c"
        - |
{{ tpl ($root.Files.Get "resources/dih_preStop.sh") $root | nindent 16 }}
{{- if $component.envConfigMap }}
envFrom:
  - configMapRef: {{ $component.envConfigMap | quote }}
{{ end }}
{{- /* END of distributedidol.dih.container.base */ -}}
{{- end -}}

{{- define "distributedidol.dih.container" -}}
{{ $root := get . "root" | required "distributedidol.dih.container: missing root" }}
{{ $component := get . "component" | required "distributedidol.dih.container: missing component" }}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "distributedidol.dih.container.base"
  "volumeMounts" (list (dict "name" "dih-persistent-storage" "mountPath" "/opt/idol/dih/data"))
  "env" (list (dict "name" "IDOL_COMPONENT_CFG" "value" "/dih/dih.cfg"))
) -}}
{{- /* END of distributedidol.dih.container */ -}}
{{- end -}}

