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
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | passageextractorSingleAgentstore(single-content) | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | answerbankSingleAgentstore(single-content) | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | single-content | 0.4.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"16000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| answerBankAgentstoreHostname | string | `"idol-answerbank-agentstore"` | Default configuration for [AnswerBank]::AgentstoreHost |
| answerBankAgentstorePort | string | `"9160"` | Default configuration for [AnswerBank]::AgentstoreAciPort |
| answerbankSingleAgentstore.aciPort | string | `"9160"` | agentstore port service will serve ACI connections on |
| answerbankSingleAgentstore.additionalVolumeMounts | list | `[{"mountPath":"/answerbank-agentstore/poststart_scripts/answerbank-agentstore-poststart.sh","name":"config-map","subPath":"answerbank-agentstore-poststart.sh"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) N.B. QMS AgentStore creates required databases on startup via poststart script mount |
| answerbankSingleAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| answerbankSingleAgentstore.existingConfigMap | string | `"idol-answerbank-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| answerbankSingleAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| answerbankSingleAgentstore.idolImage.repo | string | `"answerbank-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| answerbankSingleAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| answerbankSingleAgentstore.ingress.indexPath | string | `"/answerbank-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| answerbankSingleAgentstore.ingress.path | string | `"/answerbank-agentstore/"` | the ingress controller path to access the agentstore query service with |
| answerbankSingleAgentstore.name | string | `"idol-answerbank-agentstore"` | used to name deployment, service, ingress |
| answerbankSingleAgentstore.queryserviceACIPort | string | `"9160"` | the agentstore engine's query service ACI port |
| answerbankSingleAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide community.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"answerserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"24.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-answerserver"` | used to name deployment, service, ingress |
| passageExtractorAgentstoreHostname | string | `"idol-passageextractor-agentstore"` | Default configuration for [PassageExtractor]::AgentstoreHost |
| passageExtractorAgentstorePort | string | `"9180"` | Default configuration for [PassageExtractor]::AgentstoreAciPort |
| passageExtractorHostname | string | `"idol-passageextractor"` | Default configuration for [PassageExtractor]::IdolHost |
| passageExtractorPort | string | `"9170"` | Default configuration for [PassageExtractor]::IdolAciPort |
| passageextractorSingleAgentstore.aciPort | string | `"9180"` | agentstore port service will serve ACI connections on |
| passageextractorSingleAgentstore.additionalVolumeMounts | list | `[{"mountPath":"/passageextractor-agentstore/poststart_scripts/passageextractor-agentstore-poststart.sh","name":"config-map","subPath":"passageextractor-agentstore-poststart.sh"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) N.B. QMS AgentStore creates required databases on startup via poststart script mount |
| passageextractorSingleAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| passageextractorSingleAgentstore.existingConfigMap | string | `"idol-passageextractor-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| passageextractorSingleAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| passageextractorSingleAgentstore.idolImage.repo | string | `"passageextractor-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| passageextractorSingleAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| passageextractorSingleAgentstore.ingress.indexPath | string | `"/passageextractor-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| passageextractorSingleAgentstore.ingress.path | string | `"/passageextractor-agentstore/"` | the ingress controller path to access the agentstore query service with |
| passageextractorSingleAgentstore.name | string | `"idol-passageextractor-agentstore"` | used to name deployment, service, ingress |
| passageextractorSingleAgentstore.queryserviceACIPort | string | `"9180"` | the agentstore engine's query service ACI port |
| passageextractorSingleAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| postgresqlACIPort | string | `"9150"` | Default configuration for [PostgreSQL]::IdolAciPort |
| postgresqlHostname | string | `"idol-factbank-data-postgres"` | Default configuration for [PostgreSQL]::IdolHost |
| servicePort | string | `"16002"` | port service will serve service connections on |
| single-content.aciPort | string | `"9170"` | content port service will serve ACI connections on |
| single-content.enabled | bool | `true` | whether to deploy the single-content sub-chart. |
| single-content.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| single-content.queryserviceACIPort | string | `"9170"` | the content engine's query service ACI port |
| single-content.queryserviceName | string | `"idol-passageextractor"` | the content engine's query service name |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)