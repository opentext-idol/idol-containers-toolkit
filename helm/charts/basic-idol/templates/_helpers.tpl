{{- /*
 Copyright (c) 2019-2020 Micro Focus or one of its affiliates.

 Licensed under the MIT License (the "License"); you may not use this file
 except in compliance with the License.

 The only warranties for products and services of Micro Focus and its affiliates
 and licensors ("Micro Focus") are as may be set forth in the express warranty
 statements accompanying such products and services. Nothing herein should be
 construed as constituting an additional warranty. Micro Focus shall not be
 liable for technical or editorial errors or omissions contained herein. The
 information contained herein is subject to change without notice.

*/}}

{{/* Generate basic-idol deployment liveness probe timeouts */}}
{{- define "basicidol.deployment.standardLivenessProbe" }}
          initialDelaySeconds: 8
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{- define "basicidol.deployment.communityLivenessProbe" }}
          initialDelaySeconds: 30
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{- define "basicidol.deployment.findNifiLivenessProbe" }}
          initialDelaySeconds: 300
          timeoutSeconds: 10
          periodSeconds: 30
          failureThreshold: 5
{{- end -}}

{{- define "basicidol.deployment.reverseProxyLivenessProbe" }}
          initialDelaySeconds: 120
          timeoutSeconds: 10
          periodSeconds: 60
          failureThreshold: 3
{{- end -}}

{{- define "basicidol.deployment.mmapMediaPlaylistserverLivenessProbe" }}
          initialDelaySeconds: 60
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{- define "basicidol.deployment.mmapAppLivenessProbe" }}
          initialDelaySeconds: 120
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{- define "basicidol.deployment.mmapDbLivenessProbe" }}
          exec:
            command: ["psql", "-U", "mmap", "-d", "mmap-events", "-c", "SELECT 1"]
          initialDelaySeconds: 5
          timeoutSeconds: 3
          periodSeconds: 10
          failureThreshold: 3
{{- end -}}

{{/* Generate find initContainers */}}
{{- define "basicidol.deployment.findInitContainers" }}
      initContainers:
      - name: check-community-availability #Community must be available before Find starts up, otherwise you can't log in
        image: yauritux/busybox-curl
        args: 
        - sh 
        - -c 
        - curl "http://idol-community:9030/a=getpid"
{{- end -}}
