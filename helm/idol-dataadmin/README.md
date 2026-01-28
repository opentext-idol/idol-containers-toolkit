# idol-dataadmin

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 26.1](https://img.shields.io/badge/AppVersion-26.1-informational?style=flat-square)

Provides a Knowledge Discovery DataAdmin UI deployment.

This chart deploys a Community and View instance and (a single) Content by default, as well as AnswerServer and QMS with agentstores. If you wish to use a distributed-idol deployment instead,
set `dataadminDistributed`, disable `content.enabled` and set `indexserviceName` and `indexserviceACIPort` to appropriate values from the DIH.

An `idol-nifi` service, if one exists, will be used for Universal Viewing.

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide a user interface for managing data indexed into your Content components and optimizing search processes.

> Full documentation for DataAdmin available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-26.1/DataAdmin_26.1_Documentation/admin/> and <https://www.microfocus.com/documentation/idol/knowledge-discovery-26.1/DataAdmin_26.1_Documentation/user/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | answerserver(idol-answerserver) | ~0.6.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | community(idol-community) | ~0.8.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | ~0.16.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | ~0.5.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | qms(idol-qms) | ~0.8.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | statsserver(idol-statsserver) | ~0.1.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | view(idol-view) | ~0.9.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | content(single-content) | ~0.12.0 |

## Values

### Globals

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolOemLicenseSecret | string | `""` | Optional Secret containing OEM licensekey.dat and versionkey.dat files for licensing |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullPolicy | string | `""` | Global override value for idolImage.imagePullPolicy, has no effect if it is empty or is removed |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |

### Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.gateway | object | `{"backendTimeout":"","name":"","namespace":"","protocol":"http","requestTimeout":""}` | Gateway settings (only applies if type is 'gateway') |
| ingress.gateway.backendTimeout | string | `""` | Optional, backend timeout for ingress route |
| ingress.gateway.name | string | `""` | Optional, name of the gateway to use for ingress |
| ingress.gateway.namespace | string | `""` | Optional, namespace of the gateway to use for ingress |
| ingress.gateway.protocol | string | `"http"` | Forwarded protocol for ingress |
| ingress.gateway.requestTimeout | string | `""` | Optional, request timeout for ingress route |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.path | string | `"dataadmin"` | Ingress controller path for connections. |
| ingress.port | string | `""` | The external port the ingress is exposed on. For Kubernetes-in-Docker, this may be different to the container ingress port. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| answerserver.enabled | bool | `true` |  |
| answerserver.passageExtractorAgentstoreHostname | string | `"idol-passageextractor-agentstore"` |  |
| answerserver.passageExtractorAgentstorePort | string | `"12300"` |  |
| answerserver.passageExtractorHostname | string | `"idol-query-service"` |  |
| answerserver.passageExtractorPort | string | `"9060"` |  |
| answerserver.postgresql.fullnameOverride | string | `"idol-factbank-postgres"` |  |
| answerserver.postgresql.image.repository | string | `"bitnamilegacy/postgresql"` |  |
| answerserver.single-content.enabled | bool | `false` |  |
| community.additionalVolumeMounts.poststart.mountPath | string | `"/community/poststart_scripts/002_add_default_dataadmin_users.sh"` |  |
| community.additionalVolumeMounts.poststart.name | string | `"poststart"` |  |
| community.additionalVolumeMounts.poststart.subPath | string | `"002_add_default_dataadmin_users.sh"` |  |
| community.additionalVolumes.poststart.configMap.name | string | `"idol-dataadmin-community-poststart-scripts"` |  |
| community.additionalVolumes.poststart.name | string | `"poststart"` |  |
| community.agentStoreACIPort | string | `"12300"` |  |
| community.agentStoreName | string | `"idol-passageextractor-agentstore"` |  |
| community.enabled | bool | `true` |  |
| content.aciPort | string | `"9060"` |  |
| content.enabled | bool | `true` |  |
| content.indexPort | string | `"9061"` |  |
| content.servicePort | string | `"9062"` |  |
| dataadminDistributed | bool | `false` | Whether the query service is distributed or uses a single Content engine |
| dataadminHTTPScheme | string | `"HTTP"` | URL scheme dataadmin should use |
| dataadminLoginMethod | string | `"autonomy"` | Login method dataadmin should use |
| dataadminPassword | string | `"admin"` | Password used to login to the dataadmin UI |
| dataadminUILivenessProbe | object | `{"failureThreshold":5,"initialDelaySeconds":300,"path":"/p/overview","periodSeconds":30,"timeoutSeconds":10}` | overrides for liveness probe settings |
| dataadminUIPort | string | `"8000"` | dataadmin UI port number |
| dataadminUsername | string | `"admin"` | Username used to login to the dataadmin UI |
| existingConfigMap | string | `""` | if specified, mounted at /opt/dataadmin/home/ and expected to provide config.json |
| idol-licenseserver.enabled | bool | `true` |  |
| idol-licenseserver.licenseServerExternalName | string | `"example.license.server"` |  |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"dataadmin"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"26.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexserviceACIPort | string | `"9070"` | the indexservice port, only has an effect if dataadminDistributed is true. |
| indexserviceName | string | `"idol-index-service"` | indexserviceName is an internal parameter to specify the index service name, only has an effect if dataadminDistributed is true. |
| name | string | `"idol-dataadmin"` | The name of the dataadmin deployment if this is changed, then the name of the idol-dataadmin-community-poststart-scripts configMap used by Community should also be updated accordingly |
| nifiserviceACIPort | string | `"11000"` | list of ports for the NiFi service |
| nifiserviceName | string | `"idol-nifi"` | nifiserviceName is an internal parameter to specify the NiFi service name. |
| qms.enabled | bool | `true` |  |
| qms.queryserviceACIPort | string | `"9060"` |  |
| qms.queryserviceName | string | `"idol-query-service"` |  |
| qms.single-content.enabled | bool | `false` |  |
| queryserviceACIPort | string | `"9060"` | the queryservice port |
| queryserviceIndexPort | string | `"9061"` | the queryservice index port, only has an effect if dataadminDistributed is false |
| queryserviceName | string | `"idol-query-service"` | queryserviceName is an internal parameter to specify the query service name. |
| queryserviceServicePort | string | `"9062"` | the queryservice service port, only has an effect if dataadminDistributed is false |
| statsserver.enabled | bool | `true` |  |
| view.agentStoreACIPort | string | `"9060"` |  |
| view.agentStoreName | string | `"idol-query-service"` |  |
| view.enabled | bool | `true` |  |
| view.nifiserviceACIPort | string | `"11000"` |  |
| view.nifiserviceName | string | `"idol-nifi"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)