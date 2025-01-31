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
{{- define "distributedidol.dah.container.base" -}}
{{- $root := get . "root" | required "distributedidol.dah.container.base: missing root" -}}
{{- $component := get . "component" | required "distributedidol.dah.container.base: missing component" -}}

{{/* specific merges to container specification */}}
command: ["/bin/sh"]
args: ["-c", "cd /dah && command cp -f /etc/config/idol/dah.cfg dah.cfg && ./run_idol.sh"]
lifecycle:
  preStop:
    exec:
      command:
      - /bin/bash
      - /scripts/distributed-idol/dah_preStop.sh
{{- /* END of distributedidol.dah.container.base */ -}}
{{- end -}}

{{- define "distributedidol.dah.container" -}}
{{ $root := get . "root" | required "distributedidol.dah.container: missing root" }}
{{ $component := get . "component" | required "distributedidol.dah.container: missing component" }}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "distributedidol.dah.container.base"
  "volumeMounts" (list (dict "name" "config-volume" "mountPath" "/etc/config/idol")
    (dict "name" "dah-scripts" "mountPath" "/scripts/distributed-idol"))
  "mountConfigMap" false
  "env" (list (dict "name" "IDOL_COMPONENT_CFG"  "value" "/dah/dah.cfg"))
) -}}
{{- /* END of distributedidol.dah.container */ -}}
{{- end -}}