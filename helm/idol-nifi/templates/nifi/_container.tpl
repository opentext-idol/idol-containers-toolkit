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

{{- define "idolnifi.container.base" -}}
{{/* specific merges to container specification */}}
{{- $root := get . "root" | required "idolnifi.container.base: missing root" -}}
{{- $component := get . "component" | required "idolnifi.container.base: missing component" -}}
{{- $nifiCluster := get . "nifiCluster" | required "idolnifi.container.base: missing nifiCluster" -}}
ports:
- containerPort: 8080
  name: http
- containerPort: 11443
  name: cluster
- containerPort: 8443
  name: https
- containerPort: 6342
  name: cluster-lb
- containerPort: 11000
  name: connector-aci
- containerPort: 9092
  name: metrics
- containerPort: 10000
  name: remote-input
env:
  - name: POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP # Use pod ip
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name # Use pod name
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace # Use pod namespace
  - name: NIFI_UI_BANNER_TEXT
    value: $(POD_NAME) # Use pod name for banner
  - name: NIFI_WEB_HTTP_HOST
    value: $(POD_NAME).{{ $.nifiCluster.clusterId }}.$(POD_NAMESPACE).svc.cluster.local # Use pod fqdn as web host
  - name: NIFI_CLUSTER_NODE_ADDRESS
    value: $(POD_NAME).{{ $.nifiCluster.clusterId }}.$(POD_NAMESPACE).svc.cluster.local # Use pod fqdn as node address
  - name: NIFI_REMOTE_INPUT_SOCKET_HOST
    value: $(POD_NAME).{{ $.nifiCluster.clusterId }}.$(POD_NAMESPACE).svc.cluster.local # Use pod fqdn as input socket address
  - name: NIFI_REMOTE_INPUT_HOST
    value: $(POD_NAME).{{ $.nifiCluster.clusterId }}.$(POD_NAMESPACE).svc.cluster.local # Use pod fqdn as input host address
  - name: HOSTNAME
    value: $(POD_IP) # Use pod ip as hostname
  - name: NODE_IDENTITY
    value: $(POD_NAME) # Use pod name as identity
envFrom:
  - configMapRef:
      name: {{ $component.name }}-env
      optional: false
  - configMapRef:
      name: {{ $component.name }}-keys-env
      optional: false
{{- if $component.envConfigMap }}
  - configMapRef: 
      name: {{ $component.envConfigMap | quote }}
      optional: false
{{- end }}
lifecycle:
  postStart:
    exec:
      command:
      - /bin/bash
      - /scripts/postStart.sh
  preStop:
    exec:
      command:
      - /bin/bash
      - /scripts/preStop.sh
livenessProbe:
  exec:
   command:
     - pgrep
     - java
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
  successThreshold: 1
readinessProbe:
  tcpSocket:
    port: cluster
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
  successThreshold: 1
resources:
  requests:
    cpu: {{ $nifiCluster.resources.requests.cpu }}
    memory: {{ printf "%dMi" ( $nifiCluster.resources.requests.memoryMi | int) }}
  limits:
    cpu: {{ $nifiCluster.resources.limits.cpu }}
    memory: {{ printf "%dMi" ( $nifiCluster.resources.limits.memoryMi | int) }}
{{- if $component.containerSecurityContext.enabled }}
securityContext: {{- omit $component.containerSecurityContext "enabled" | toYaml | nindent 10 }}
{{- end -}}

{{- /* END of idolnifi.container.base */ -}}
{{- end -}}

{{- define "idolnifi.container" -}}
{{- $root := get . "root" | required "idolnifi.container: missing root" -}}
{{- $component := get . "component" | required "idolnifi.container: missing component" -}}
{{- $nifiCluster := get . "nifiCluster" | required "idolnifi.container: missing nifiCluster" -}}
{{- include "idol-library.util.merge" (dict
  "root" $root
  "component" $component
  "nifiCluster" $nifiCluster
  "source" "idol-library.aciserver.container.base.v1"
  "destination" "idolnifi.container.base" 
  "volumeMounts" (list (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/conf" "subPath" "conf" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/data" "subPath" "data" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/run" "subPath" "run" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/state" "subPath" "state" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/keytool" "subPath" "keytool" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/content_repository" "subPath" "content_repository" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/database_repository" "subPath" "database_repository" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/flowfile_repository" "subPath" "flowfile_repository" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/idol_repository" "subPath" "idol_repository" "readOnly" false)
                       (dict "name" "statedata" "mountPath" "/opt/nifi/nifi-current/provenance_repository" "subPath" "provenance_repository" "readOnly" false)
                       (dict "name" "data" "mountPath" "/idol-ingest" "subPath" "idol-ingest" "readOnly" false)
                       (dict "name" "scripts" "mountPath" "/scripts" "readOnly" false)
                       (dict "name" "dshm" "mountPath" "/dev/shm" "readOnly" false))
  "mountConfigMap" false
) -}}
{{- /* END of idolnifi.container */ -}}
{{- end -}}