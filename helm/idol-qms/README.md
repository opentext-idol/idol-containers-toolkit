# idol-qms



![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 23.4](https://img.shields.io/badge/AppVersion-23.4-informational?style=flat-square) 

Provides an IDOL QMS deployment.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)
- IDOL Content/Agentstore (`queryserviceName`, `queryserviceACIPort`, `agentStoreName`, `agentStoreACIPort`)

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide query & result modification and promotion management functionality.

> Full documentation for QMS available from https://www.microfocus.com/documentation/idol/IDOL_23_4/QMS_23.4_Documentation/Help/







## Requirements

| Repository | Name | Version |
|------------|------|---------|
| file://../single-content | singleAgentstore(single-content) | 0.4.0 |
| file://../single-content | single-content | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.4.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"16000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| agentStoreACIPort | string | `"9150"` | Default configuration for [PromotionAgentStore]::Port |
| agentStoreName | string | `"qms-agentstore-query-service"` | Default configuration for [PromotionAgentStore]::Host |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide community.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"qms"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"23.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-qms"` | used to name deployment, service, ingress |
| queryserviceACIPort | string | `"9100"` | Default configuration for [IDOL]::Port |
| queryserviceName | string | `"idol-query-service"` | Default configuration for [IDOL]::Host |
| servicePort | string | `"16002"` | port service will serve service connections on |
| single-content.aciPort | string | `"9100"` | content port service will serve ACI connections on |
| single-content.enabled | bool | `true` | whether to deploy the single-content sub-chart. |
| single-content.queryserviceACIPort | string | `"9100"` | the content engine's query service ACI port |
| single-content.queryserviceName | string | `"idol-query-service"` | the content engine's query service name |
| singleAgentstore.aciPort | string | `"9150"` | agentstore port service will serve ACI connections on |
| singleAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| singleAgentstore.existingConfigMap | string | `"qms-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| singleAgentstore.idolImage.repo | string | `"qms-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| singleAgentstore.indexserviceName | string | `"idol-agentstore-index-service"` | the agentstore engine's index service name |
| singleAgentstore.ingress.indexPath | string | `"/agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| singleAgentstore.ingress.path | string | `"/agentstore/"` | the ingress controller path to access the agentstore query service with |
| singleAgentstore.name | string | `"qms-agentstore"` | used to name deployment, service, ingress |
| singleAgentstore.queryserviceACIPort | string | `"9150"` | the agentstore engine's query service ACI port |
| singleAgentstore.queryserviceName | string | `"qms-agentstore-query-service"` | the agentstore engine's query service name |

