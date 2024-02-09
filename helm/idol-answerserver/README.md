# idol-answerserver

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 24.1](https://img.shields.io/badge/AppVersion-24.1-informational?style=flat-square)

Provides an IDOL answerserver deployment.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)
- IDOL Content/Agentstore (`answerBankAgentstoreHostname`, `answerBankAgentstorePort`, `passageExtractorHostname`, `passageExtractorPort`, `passageExtractorAgentstoreHostname`, `passageExtractorAgentstorePort`)

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide query & result modification and promotion management functionality.

> Full documentation for answerserver available from https://www.microfocus.com/documentation/idol/IDOL_24.1/answerserver_24.1_Documentation/Help/

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 13.2.3 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.6.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | passageextractorAgentstore(single-content) | 0.5.1 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | answerbankAgentstore(single-content) | 0.5.1 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | single-content | 0.5.1 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"12000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[{"mountPath":"/answerserver/prestart_scripts/00_config.sh","name":"idol-answerserver-scripts","subPath":"config.sh"}]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[{"configMap":{"name":"idol-answerserver-scripts"},"name":"idol-answerserver-scripts"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| answerBankAgentstoreHostname | string | `"idol-answerbank-agentstore"` | Default configuration for [AnswerBank]::AgentstoreHost |
| answerBankAgentstorePort | string | `"12200"` | Default configuration for [AnswerBank]::AgentstoreAciPort |
| answerbankAgentstore.aciPort | string | `"12200"` | agentstore port service will serve ACI connections on |
| answerbankAgentstore.additionalVolumeMounts | list | `[{"mountPath":"/answerbank-agentstore/poststart_scripts/answerbank-agentstore-poststart.sh","name":"config-map","subPath":"answerbank-agentstore-poststart.sh"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) N.B. QMS AgentStore creates required databases on startup via poststart script mount |
| answerbankAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| answerbankAgentstore.existingConfigMap | string | `"idol-answerbank-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| answerbankAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| answerbankAgentstore.idolImage.repo | string | `"answerbank-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| answerbankAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| answerbankAgentstore.ingress.indexPath | string | `"/answerbank-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| answerbankAgentstore.ingress.path | string | `"/answerbank-agentstore/"` | the ingress controller path to access the agentstore query service with |
| answerbankAgentstore.name | string | `"idol-answerbank-agentstore"` | used to name deployment, service, ingress |
| answerbankAgentstore.queryserviceACIPort | string | `"12200"` | the agentstore engine's query service ACI port |
| answerbankAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide answerserver.cfg |
| factbankPostgresqlPort | string | `"5432"` | FactBank Postgresql Port configuration |
| factbankPostgresqlServer | string | `"idol-factbank-postgres"` | FactBank Postgresql Server configuration |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"answerserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
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
| name | string | `"idol-answerserver"` | used to name deployment, service, ingress |
| passageExtractorAgentstoreHostname | string | `"idol-passageextractor-agentstore"` | Default configuration for [PassageExtractor]::AgentstoreHost |
| passageExtractorAgentstorePort | string | `"12300"` | Default configuration for [PassageExtractor]::AgentstoreAciPort |
| passageExtractorHostname | string | `"idol-query-service"` | Default configuration for [PassageExtractor]::IdolHost |
| passageExtractorPort | string | `"9100"` | Default configuration for [PassageExtractor]::IdolAciPort |
| passageextractorAgentstore.aciPort | string | `"12300"` | agentstore port service will serve ACI connections on |
| passageextractorAgentstore.additionalVolumeMounts | list | `[{"mountPath":"/passageextractor-agentstore/poststart_scripts/passageextractor-agentstore-poststart.sh","name":"config-map","subPath":"passageextractor-agentstore-poststart.sh"},{"mountPath":"/passageextractor-agentstore/poststart_scripts/002_startup_tasks.sh","name":"config-map","subPath":"passageextractor-agentstore-poststart_2.sh"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) N.B. QMS AgentStore creates required databases on startup via poststart script mount |
| passageextractorAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| passageextractorAgentstore.existingConfigMap | string | `"idol-passageextractor-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| passageextractorAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| passageextractorAgentstore.idolImage.repo | string | `"passageextractor-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| passageextractorAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| passageextractorAgentstore.ingress.indexPath | string | `"/passageextractor-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| passageextractorAgentstore.ingress.path | string | `"/passageextractor-agentstore/"` | the ingress controller path to access the agentstore query service with |
| passageextractorAgentstore.name | string | `"idol-passageextractor-agentstore"` | used to name deployment, service, ingress |
| passageextractorAgentstore.queryserviceACIPort | string | `"12300"` | the agentstore engine's query service ACI port |
| passageextractorAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| postgresql.auth.database | string | `"factbank-data"` |  |
| postgresql.auth.password | string | `"password"` |  |
| postgresql.auth.username | string | `"postgres"` |  |
| postgresql.enabled | bool | `true` | whether to deploy the postgresql subchart |
| postgresql.primary.containerSecurityContext.enabled | bool | `true` |  |
| postgresql.primary.initdb.scriptsConfigMap | string | `"idol-factbank-postgres-init"` |  |
| postgresql.primary.persistence.storageClass | string | `"standard"` |  |
| postgresql.primary.podSecurityContext.enabled | bool | `true` |  |
| servicePort | string | `"12002"` | port service will serve service connections on |
| single-content.aciPort | string | `"9100"` | content port service will serve ACI connections on |
| single-content.enabled | bool | `true` | whether to deploy the single-content sub-chart. |
| single-content.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| single-content.indexserviceACIPort | string | `"9070"` |  |
| single-content.indexserviceName | string | `"idol-index-service"` |  |
| single-content.queryserviceACIPort | string | `"9100"` | the content engine's query service ACI port |
| single-content.queryserviceName | string | `"idol-query-service"` | the content engine's query service name |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)