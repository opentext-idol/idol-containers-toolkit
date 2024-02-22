# BEGIN COPYRIGHT NOTICE
# Copyright 2022-2024 Open Text.
# 
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE

{{ define "idolnifi.initcontainer" -}}
{{/* specific merges to statefulset specification */}}
{{- $component := get . "component" | required "idolnifi.initcontainer: missing component" -}}
name: wait-for-zookeeper
image: docker.io/busybox:1.36
command:
- sh
- -c
- |
  echo "Connecting to Zookeeper ${NIFI_ZK_CONNECT_STRING}"
  until nc -vzw 1 zookeeper 2181 ; do
    echo "Waiting for zookeeper to start"
    sleep 3
  done
envFrom:
- configMapRef:
    name: idol-nifi-env
    optional: false
resources:
  requests:
    cpu: 20m
    memory: 10Mi
  limits:
    cpu: 20m
    memory: 10Mi
{{- if $component.containerSecurityContext.enabled }}
securityContext: {{- omit $component.containerSecurityContext "enabled" | toYaml | nindent 2 }}
  readOnlyRootFilesystem: true
{{- end }}
{{- end -}}
