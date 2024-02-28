# idol-nifi



![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![AppVersion: 24.1.0](https://img.shields.io/badge/AppVersion-24.1.0-informational?style=flat-square) 

Provides a scaleable IDOL NiFi cluster instance (NiFi, NiFi Registry and ZooKeeper).

> Full documentation for IDOL NiFi Ingest available from https://www.microfocus.com/documentation/idol/IDOL_24_1/NiFiIngest_24.1_Documentation/Help/

## Related Documentation

* https://nifi.apache.org/
* https://zookeeper.apache.org/







## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.9.0 |
| https://kubernetes-sigs.github.io/metrics-server | metrics-server | 3.8.2 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | 0.2.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"privileged":false}` | container security context definition  See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container |
| envConfigMap | string | `""` |  |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullPolicy | string | `""` | Global override value for idolImage.imagePullPolicy, has no effect if it is empty or is removed |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idol-licenseserver.enabled | bool | `false` | whether to deploy an IDOL LicenseServer service abstraction |
| idol-licenseserver.licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| idol-licenseserver.licenseServerService | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"nifi-full"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version}. |
| idolImage.version | string | `"24.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexserviceACIPort | string | `"9070"` | the ACI port of the indexing IDOL component |
| indexserviceName | string | `"idol-index-service"` | the hostname of the indexing IDOL component |
| ingressBasicAuthData | string | `"YWRtaW46JGFwcjEkSDY1dnBkTU8kMXAxOGMxN3BuZVFUT2ZjVC9TZkZzMQo="` | base64 encoded htpasswd https://httpd.apache.org/docs/2.4/misc/password_encryptions.html. Default is admin/admin |
| ingressClassName | string | `""` | Optional, https://kubernetes.io/docs/concepts/services-networking/ingress/#the-ingress-resource, applied to all ingress objects |
| ingressProxyBodySize | string | `"2048m"` | the maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingressType | string | `"nginx"` | setup ingress for that controller type. Valid values are nginx or haproxy (used by OpenShift) |
| metrics-server.args[0] | string | `"--kubelet-insecure-tls"` |  |
| name | string | `"idol-nifi"` | used to name statefulset, service, ingress |
| nifi.autoScaling.enabled | bool | `true` | deploy a horizontal pod autoscaler for the nifi statefulset |
| nifi.autoScaling.maxReplicas | int | `8` | the maximum size of the nifi statefulset |
| nifi.autoScaling.metrics | list | `[{"resource":{"name":"memory","target":{"averageUtilization":90,"type":"Utilization"}},"type":"Resource"},{"resource":{"name":"cpu","target":{"averageUtilization":90,"type":"Utilization"}},"type":"Resource"}]` | one or more metrics controlling the horizontal pod autoscaler (https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/#HorizontalPodAutoscalerSpec) |
| nifi.autoScaling.minReplicas | int | `1` | the minimum size of the nifi statefulset |
| nifi.dataVolume.storageClass | string | `"idol-nifi-storage-class"` |  |
| nifi.dataVolume.volumeSize | string | `"16Gi"` |  |
| nifi.flowfile | string | `"/scripts/flow-basic-idol.json"` | the flowfile definition to import.  Set this to any non-existing path to bypass flow import (start with a blank flow). Customize the NiFi image and set this to a filepath within that image to import your own customized flow. |
| nifi.ingress.aciHost | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifi.ingress.annotations | object | `{}` | optional ingress annotations |
| nifi.ingress.enabled | bool | `true` | whether to deploy ingress for nifi |
| nifi.ingress.host | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifi.ingress.proxyHost | string | `""` | optional nifi.web.proxy.host value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties) |
| nifi.ingress.proxyPath | string | `""` | optional nifi.web.proxy.context.path value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties) |
| nifi.jvmMemoryRatio | float | `0.5` | What proportion of the pod memory to allocate for JVM usage |
| nifi.resources | object | `{"limits":{"cpu":"4000m","memoryMi":8192},"requests":{"cpu":"2000m","memoryMi":4096}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |
| nifi.resources.limits.memoryMi | int | `8192` | memory limit in mebibytes (value used in jvm memory calculation) |
| nifi.resources.requests.memoryMi | int | `4096` | memory requested in mebibytes (value used in jvm memory calculation) |
| nifiRegistry.ingress.annotations | object | `{}` | optional ingress annotations |
| nifiRegistry.ingress.enabled | bool | `true` | whether to deploy ingress for nifi |
| nifiRegistry.ingress.host | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifiRegistry.resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"1Gi"}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |
| podSecurityContext | object | `{"enabled":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | pod security context definition  See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| usingTLS | bool | `false` | whether ports are configured to use TLS (https). |
| zookeeper.resources | object | `{"limits":{"cpu":"200m","memory":"500Mi"},"requests":{"cpu":"200m","memory":"500Mi"}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |


----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)