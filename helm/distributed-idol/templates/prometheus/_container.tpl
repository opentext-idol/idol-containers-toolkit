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

{{- define "distributedidol.prometheus.container.base" -}}
{{- $root := get . "root" | required "distributedidol.prometheus.container.base: missing root" -}}
{{- $component := get . "component" | required "distributedidol.prometheus.container.base: missing component" -}}
{{/* specific merges to container specification */}}
{{- if and ($root.Values.autoscaling.enabled) (not $root.Values.setupMirrored) }}
name: prometheus-exporter
image: python:3.11
{{- if (coalesce $root.Values.global.http_proxy $root.Values.global.https_proxy) }}
envFrom:
  - configMapRef:
      name: http-proxy-config
{{- end }}
workingDir: /usr/src/app
command: ["/bin/sh"]
args:
  - "-c"
  - |
    mkdir -p /usr/src/app &&
    echo "Copying files" &&
    cp /mnt/python/* /usr/src/app &&
    cd /usr/src/app &&
    echo "Installing" &&
    pip install --no-cache-dir -r requirements.txt &&
    echo "Running" &&
    python dih_prometheus_exporter.py &
    RUN_PID=$!
    trap 'kill "${RUN_PID}"; wait "${RUN_PID}"' SIGINT SIGTERM
    wait "${RUN_PID}"
    echo "python exited"
ports:
  - containerPort: {{ $component.prometheusPort| int }}
    name: metrics-port
    protocol: TCP
{{- end }}
{{- end }}


{{- define "distributedidol.prometheus.container" -}}
{{ $root := get . "root" | required "distributedidol.prometheus.container: missing root" }}
{{ $component := get . "component" | required "distributedidol.prometheus.container: missing component" }}
{{- if and ($root.Values.autoscaling.enabled) (not $root.Values.setupMirrored) }}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "distributedidol.prometheus.container.base"
  "volumeMounts" (list (dict "name" "dih-prometheus-exporter-python" "mountPath" "/mnt/python")
                       (dict "name" "python-src-app" "mountPath" "/usr/src/app")
                       (dict "name" "python-local" "mountPath" "/.local"))
) -}}
{{- end -}}
{{- /* END of distributedidol.prometheus.container */ -}}
{{- end -}}