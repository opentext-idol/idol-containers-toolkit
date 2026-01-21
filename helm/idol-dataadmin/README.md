# idol-dataadmin

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 25.4](https://img.shields.io/badge/AppVersion-25.4-informational?style=flat-square)

Provides a Knowledge Discovery DataAdmin UI deployment.

Depends on connections to:

- Knowledge Discovery LicenseServer (`idol-licenseserver.licenseServerExternalName`)
- Knowledge Discovery Content (`queryserviceName`, `queryserviceACIPort`, `queryserviceIndexPort`)

This chart deploys a Community and View instance and (a single) Content by default, as well as AnswerServer and QMS with agentstores. If you wish to use a distributed-idol deployment instead,
set `dataadminDistributed`, disable `content.enabled` and set `indexserviceName` and `indexserviceACIPort` to appropriate values from the DIH.

An `idol-nifi` service, if one exists, will be used for Universal Viewing.

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide a user interface for managing data indexed into your Content components and optimizing search processes.

> Full documentation for DataAdmin available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DataAdmin_25.4_Documentation/admin/> and <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DataAdmin_25.4_Documentation/user/>

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

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| answerserver.enabled | bool | `true` |  |
| answerserver.passageExtractorACIPort | string | `"9060"` |  |
| answerserver.passageExtractorAgentstoreHostname | string | `"idol-passageextractor-agentstore"` |  |
| answerserver.passageExtractorAgentstorePort | string | `"12300"` |  |
| answerserver.passageExtractorHostname | string | `"idol-query-service"` |  |
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
| dataadminDistributed | bool | `false` |  |
| dataadminEndpointName | string | `"dataadmin"` |  |
| dataadminHTTPScheme | string | `"HTTP"` |  |
| dataadminIngressName | string | `"idol-dataadmin-ingress"` |  |
| dataadminLoginMethod | string | `"autonomy"` |  |
| dataadminPassword | string | `"admin"` |  |
| dataadminUILivenessProbe.failureThreshold | int | `5` |  |
| dataadminUILivenessProbe.initialDelaySeconds | int | `300` |  |
| dataadminUILivenessProbe.path | string | `"/p/overview"` |  |
| dataadminUILivenessProbe.periodSeconds | int | `30` |  |
| dataadminUILivenessProbe.timeoutSeconds | int | `10` |  |
| dataadminUIName | string | `"idol-dataadmin"` |  |
| dataadminUIPort | string | `"8000"` |  |
| dataadminUsername | string | `"admin"` |  |
| existingConfigMap | string | `""` | if specified, mounted at /opt/dataadmin/home/ and expected to provide config.json |
| idol-licenseserver.enabled | bool | `true` |  |
| idol-licenseserver.licenseServerExternalName | string | `"example.license.server"` |  |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"dataadmin"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"26.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexserviceACIPort | string | `"9070"` |  |
| indexserviceName | string | `"idol-index-service"` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `true` |  |
| ingress.gateway.backendTimeout | string | `""` | Optional, backend timeout for ingress route |
| ingress.gateway.name | string | `""` | Optional, name of the gateway to use for ingress |
| ingress.gateway.namespace | string | `""` | Optional, namespace of the gateway to use for ingress |
| ingress.gateway.protocol | string | `"http"` | Forwarded protocol for ingress |
| ingress.gateway.requestTimeout | string | `""` | Optional, request timeout for ingress route |
| ingress.host | string | `""` |  |
| ingress.port | string | `""` |  |
| ingress.proxyBodySize | string | `"2048m"` |  |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` |  |
| nifiserviceACIPort | string | `"11000"` |  |
| nifiserviceName | string | `"idol-nifi"` |  |
| qms.enabled | bool | `true` |  |
| qms.queryserviceACIPort | string | `"9060"` |  |
| qms.queryserviceName | string | `"idol-query-service"` |  |
| qms.single-content.enabled | bool | `false` |  |
| queryserviceACIPort | string | `"9060"` |  |
| queryserviceIndexPort | string | `"9061"` |  |
| queryserviceName | string | `"idol-query-service"` |  |
| queryserviceServicePort | string | `"9062"` |  |
| statsserver.enabled | bool | `true` |  |
| view.agentStoreACIPort | string | `"9060"` |  |
| view.agentStoreName | string | `"idol-query-service"` |  |
| view.enabled | bool | `true` |  |
| view.nifiServiceACIPort | string | `"11000"` |  |
| view.nifiServiceName | string | `"idol-nifi"` |  |
| webappPortName | string | `"web-app"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)