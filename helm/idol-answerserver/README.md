# idol-answerserver

![Version: 0.5.1](https://img.shields.io/badge/Version-0.5.1-informational?style=flat-square) ![AppVersion: 25.1](https://img.shields.io/badge/AppVersion-25.1-informational?style=flat-square)

Provides a Knowledge Discovery AnswerServer deployment.

Depends on connections to:

- Knowledge Discovery LicenseServer (`licenseServerHostname`)
- Knowledge Discovery Content/Agentstore (`answerBankAgentstoreHostname`, `answerBankAgentstorePort`, `passageExtractorHostname`, `passageExtractorPort`, `passageExtractorAgentstoreHostname`, `passageExtractorAgentstorePort`)

The config file can be overridden via `existingConfigMap`.

This chart provides an `idol-answerserver` system along with answerbank, factbank and passagegextractor systems.
These systems are empty initially, and data can be indexed into them via the provided index services.
For example, the passageextractor system accesses documents stored in the content engine with `idol-index-service`
and `idol-query-service` services. These systems are all optional and can be disabled as desired.
To use a passageextractorLLM system, you must first set up a persistent volume and index the appropriate model
files, then redeploy the chart with LLM configuration information in your answerserver configuration file.

> Full documentation for AnswerServer available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.1/AnswerServer_25.1_Documentation/Help/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | postgresql | 13.2.3 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | ~0.15.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | passageextractorAgentstore(single-content) | ~0.11.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | answerbankAgentstore(single-content) | ~0.11.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | single-content | ~0.11.0 |

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
| ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overridden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.path | string | `"/answerserver/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/answerserver/service/"` | Ingress controller path for service connections. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"12000"` | port service will serve ACI connections on |
| additionalVolumeMounts | object | `{"idol-answerserver-scripts":{"mountPath":"/answerserver/prestart_scripts/00_config.sh","name":"idol-answerserver-scripts","subPath":"config.sh"}}` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| additionalVolumes | object | `{"idol-answerserver-scripts":{"configMap":{"name":"idol-answerserver-scripts"},"name":"idol-answerserver-scripts"}}` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| annotations | object | `{}` | Additional annotations applied to deployment/statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| answerBankAgentstoreHostname | string | `"idol-answerbank-agentstore"` | Default configuration for [AnswerBank]::AgentstoreHost |
| answerBankAgentstorePort | string | `"12200"` | Default configuration for [AnswerBank]::AgentstoreAciPort |
| answerServerStorageClass | string | `"idol-answerserver-storage-class"` | Name of the storage class used to provision a PersistentVolume for each AnswerServer instance. The associated PVCs are named state-{name}-{pod number} |
| answerServerVolumeSize | string | `"2Gi"` | Size of the PersistentVolumeClaim that is created for each AnswerServer instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisfy the claims made for the desired number of AnswerServer instances. |
| answerbankAgentstore.aciPort | string | `"12200"` | agentstore port service will serve ACI connections on |
| answerbankAgentstore.additionalVolumeMounts | object | `{"answerbank-agentstore-poststart":{"mountPath":"/answerbank-agentstore/poststart_scripts/002_startup_tasks.sh","name":"config-map","subPath":"answerbank-agentstore-poststart.sh"}}` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) N.B. AgentStore creates required databases on startup via poststart script mount |
| answerbankAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| answerbankAgentstore.existingConfigMap | string | `"idol-answerbank-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| answerbankAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| answerbankAgentstore.idolImage.repo | string | `"answerbank-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| answerbankAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| answerbankAgentstore.ingress.indexPath | string | `"/answerbank-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| answerbankAgentstore.ingress.path | string | `"/answerbank-agentstore/"` | the ingress controller path to access the agentstore query service with |
| answerbankAgentstore.ingress.servicePath | string | `"/answerbank-agentstore/service/"` | the ingress controller path for agentstore service connections |
| answerbankAgentstore.name | string | `"idol-answerbank-agentstore"` | used to name deployment, service, ingress |
| answerbankAgentstore.queryserviceACIPort | string | `"12200"` | the agentstore engine's query service ACI port |
| answerbankAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide answerserver.cfg |
| factbankPostgresqlPort | string | `"5432"` | FactBank Postgresql Port configuration |
| factbankPostgresqlServer | string | `"idol-factbank-postgres"` | FactBank Postgresql Server configuration |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"answerserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"25.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| labels | object | `{}` | Additional labels applied to all objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-answerserver"` | used to name deployment, service, ingress |
| passageExtractorAgentstoreHostname | string | `"idol-passageextractor-agentstore"` | Default configuration for [PassageExtractor]::AgentstoreHost |
| passageExtractorAgentstorePort | string | `"12300"` | Default configuration for [PassageExtractor]::AgentstoreAciPort |
| passageExtractorHostname | string | `"idol-query-service"` | Default configuration for [PassageExtractor]::IdolHost |
| passageExtractorPort | string | `"9100"` | Default configuration for [PassageExtractor]::IdolAciPort |
| passageextractorAgentstore.aciPort | string | `"12300"` | agentstore port service will serve ACI connections on |
| passageextractorAgentstore.additionalVolumeMounts | object | `{"passageextractor-agentstore-poststart":{"mountPath":"/passageextractor-agentstore/poststart_scripts/002_startup_tasks.sh","name":"config-map","subPath":"passageextractor-agentstore-poststart.sh"}}` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) N.B. AgentStore creates required databases on startup via poststart script mount |
| passageextractorAgentstore.enabled | bool | `true` | whether to deploy the single-content sub-chart that uses an IDOL Agentstore    configuration file and docker image. |
| passageextractorAgentstore.existingConfigMap | string | `"idol-passageextractor-agentstore-cfg"` | the config map to use for providing a qms-agentstore configuration. |
| passageextractorAgentstore.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| passageextractorAgentstore.idolImage.repo | string | `"passageextractor-agentstore"` | overrides the default value for single-content.idolImage.repo ("content")    to guarantee that we use an IDOL Agentstore docker image. |
| passageextractorAgentstore.indexserviceName | string | `""` | the agentstore engine's index service name |
| passageextractorAgentstore.ingress.indexPath | string | `"/passageextractor-agentstore-index/"` | the ingress controller path to access the agentstore index service with |
| passageextractorAgentstore.ingress.path | string | `"/passageextractor-agentstore/"` | the ingress controller path to access the agentstore query service with |
| passageextractorAgentstore.ingress.servicePath | string | `"/passageextractor-agentstore/service/"` | the ingress controller path for agentstore service connections |
| passageextractorAgentstore.name | string | `"idol-passageextractor-agentstore"` | used to name deployment, service, ingress |
| passageextractorAgentstore.queryserviceACIPort | string | `"12300"` | the agentstore engine's query service ACI port |
| passageextractorAgentstore.queryserviceName | string | `""` | the agentstore engine's query service name |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| postgresql.auth.database | string | `"factbank-data"` |  |
| postgresql.auth.password | string | `"password"` |  |
| postgresql.auth.username | string | `"postgres"` |  |
| postgresql.enabled | bool | `true` | whether to deploy the postgresql subchart |
| postgresql.primary.containerSecurityContext.enabled | bool | `true` |  |
| postgresql.primary.initdb.scriptsConfigMap | string | `"idol-factbank-postgres-init"` |  |
| postgresql.primary.persistence.storageClass | string | `"standard"` |  |
| postgresql.primary.podSecurityContext.enabled | bool | `true` |  |
| replicas | int | `1` | number of replica pods for this container (defaults to 1) |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| servicePort | string | `"12002"` | port service will serve service connections on |
| single-content.aciPort | string | `"9100"` | content port service will serve ACI connections on |
| single-content.enabled | bool | `true` | whether to deploy the single-content sub-chart. |
| single-content.idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| single-content.indexserviceACIPort | string | `"9070"` |  |
| single-content.indexserviceName | string | `"idol-index-service"` |  |
| single-content.queryserviceACIPort | string | `"9100"` | the content engine's query service ACI port |
| single-content.queryserviceName | string | `"idol-query-service"` | the content engine's query service name |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| workingDir | string | `"/answerserver"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)