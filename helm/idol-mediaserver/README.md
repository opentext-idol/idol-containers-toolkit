# idol-mediaserver

![Version: 0.2.0](https://img.shields.io/badge/Version-0.2.0-informational?style=flat-square) ![AppVersion: 24.1](https://img.shields.io/badge/AppVersion-24.1-informational?style=flat-square)

Provides an IDOL MediaServer deployment.

Default configuration is to provide OCR and STT functionality.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide optical class recognition and speech-to-text functionality.

> Full documentation for MediaServer available from https://www.microfocus.com/documentation/idol/IDOL_24_1/MediaServer_24.1_Documentation/Help/

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.11.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"14000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| audioChannels | int | `1` | Allocate one channel for each concurrent process action that includes audio processing Audio channels are used for each of the following processes:   Audio categorization   Audio matching   Language identification   Speaker identification   Speech-to-text   All video management features |
| containerSecurityContext | object | `{"enabled":false}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide mediaserver.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"mediaserver-english"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"24.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overriden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.path | string | `"/mediaserver/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/mediaserver/service/"` | Ingress controller path for service connections. |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":30}` | container livenessProbe settings |
| modules | list | `["ocr","speechtotext"]` | Which modules to enable Enable only the modules you want to use, to reduce memory usage and improve startup speed |
| name | string | `"idol-mediaserver"` | used to name deployment, service, ingress |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| processMaximumThreads | int | `1` | The maximum number of Process actions that can be run simultaneously Increase this value to match available Channels, if you increase the Channels values See MediaServer documentation for more information about Process actions |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| servicePort | string | `"14001"` | port service will serve service connections on |
| surveillanceChannels | int | `1` | Allocate one channel for each analysis task, multiplied by the number of concurrent process actions Surveillance channels are used for each of the following processes:  Face detection  Number plate recognition (ANPR)  Object class recognition (but only with certain pre-trained recognizers).  Scene analysis  Text detection  All video management features |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| videoManagementChannels | int | `1` | Allocate one video management channel for each concurrent process action that does not require an audio, surveillance, or visual channel These channels will be used for the following:  Ingest (apart from the Receive ingest engine, which requires a visual channel)  Analysis:   Keyframe   News segmentation   Text segmentation  Encoding  Event stream processing  Transformation  Output |
| visualChannels | int | `1` | Allocate one channel for each concurrent process action that includes any visual analytics. Visual channels are used for each of the following processes:  Ingesting records from another Media Server for further processing  All analysis operations except audio processing  Face recognition on large databases (maximum 250,000 faces, every additional 250,000 faces requires an additional visual channel)  All surveillance and video management features |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.12.0](https://github.com/norwoodj/helm-docs/releases/v1.12.0)