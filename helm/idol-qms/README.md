# idol-qms



![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![AppVersion: 24.1](https://img.shields.io/badge/AppVersion-24.1-informational?style=flat-square) 

Provides an IDOL QMS deployment.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)
- IDOL Content/Agentstore (`queryserviceName`, `queryserviceACIPort`, `agentStoreName`, `agentStoreACIPort`)

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide query & result modification and promotion management functionality.

> Full documentation for QMS available from https://www.microfocus.com/documentation/idol/IDOL_24.1/QMS_24.1_Documentation/Help/







## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.9.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | singleAgentstore(single-content) | 0.6.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | single-content | 0.6.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"16000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| agentStoreACIPort | string | `"9150"` | Default configuration for [PromotionAgentStore]::Port |
| agentStoreName | string | `"idol-qms-agentstore"` | Default configuration for [PromotionAgentStore]::Host |
| containerSecurityContext | object | `{"enabled":false}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide community.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"qms"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"24.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overriden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-qms"` | used to name deployment, service, ingress |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| queryserviceACIPort | string | `"9100"` | Default configuration for [IDOL]::Port |
| queryserviceName | string | `"idol-query-service"` | Default configuration for [IDOL]::Host |
| servicePort | string | `"16002"` | port service will serve service connections on |
| single-content.aciPort | string | `"9100"` | content port service will serve ACI connections on |
| single-content.enabled | bool | `true` | whether to deploy the single-content sub-chart. |
| single-content.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| single-content.queryserviceACIPort | string | `"9100"` | the content engine's query service ACI port |
| single-content.queryserviceName | string | `"idol-query-service"` | the content engine's query service name |
| singleAgentstore.aciPort | string | `"9150"` | agentstore port service will serve ACI connections on |
| singleAgentstore.additionalVolumeMounts | list | `[{"mountPath":"/qms-agentstore/poststart_scripts/qms-agentstore-poststart.sh","name":"config-map","subPath":"qms-agentstore-poststart.sh"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) N.B. QMS AgentStore creates required databases on startup via poststart script mount |
| singleAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| singleAgentstore.existingConfigMap | string | `"idol-qms-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| singleAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| singleAgentstore.idolImage.repo | string | `"qms-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| singleAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| singleAgentstore.ingress.indexPath | string | `"/qms-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| singleAgentstore.ingress.path | string | `"/qms-agentstore/"` | the ingress controller path to access the agentstore query service with |
| singleAgentstore.name | string | `"idol-qms-agentstore"` | used to name deployment, service, ingress |
| singleAgentstore.queryserviceACIPort | string | `"9150"` | the agentstore engine's query service ACI port |
| singleAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |


----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.13.1](https://github.com/norwoodj/helm-docs/releases/v1.13.1)