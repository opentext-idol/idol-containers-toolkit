# idol-omnigroupserver

![Version: 0.8.2](https://img.shields.io/badge/Version-0.8.2-informational?style=flat-square) ![AppVersion: 25.1](https://img.shields.io/badge/AppVersion-25.1-informational?style=flat-square)

Provides an Knowledge Discovery OmniGroupServer deployment.

Whilst this can be deployed 'as-is', it is expected that a real deployment will
require configuration particular to the repositories the OGS instance needs to
provide user/group information for.

Consumers of this chart are encouraged to use this as a subchart, providing an
additional config-map with the OGS config file - see `.Values.existingConfigMap`

> Full documentation for OmniGroupServer available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.1/OmniGroupServer_25.1_Documentation/Help/>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | ~0.15.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | ~0.4.0 |

## Automated OAuth Configuration Generation at Prestart

If `oauthToolConfigMap` is set to a non-empty string, then the OmniGroupServer pod will
attempt to automatically generate any missing OAuth configuration at Prestart.

1. The Prestart script will detect any [External Configuration File Includes](https://www.microfocus.com/documentation/idol/knowledge-discovery-25.1/OmniGroupServer_25.1_Documentation/Help/Content/Configuration/_ACI_Config_Intro.htm#Include-an-Exter)
   of the "Merge a section of an external configuration file into a specified section with a different name" form,
   where the `SharedSection` is "OAUTH".
2. For each matching external configuration section include in the OmniGroupServer configuration, if the
   required file path (referred to as `ConfigurationFile.cfg` in the linked documentation) is missing,
   an attempt to generate it via `oauth_tool` will be made. `oauth_tool` will be invoked with the
   `oauth_tool.cfg` supplied in the ConfigMap referred to by `oauthToolConfigMap`, and the section name
   specified by `SectionName` in the external configuration section include.

### Constraints

1. The required file path (referred to as `ConfigurationFile.cfg` in the linked documentation) MUST NOT
   be `/omnigroupserver/oauth.cfg`.
2. The oauth_tool workflow MUST NOT require user interaction. Some OAuth providers require user interaction in
   their workflow. For any OAuth configuration where this is the case, the OAuth workflow must be conducted elsewhere
   and the resulting files mounted into the Omnigroupserver container at the expected places for your configuration -
   the presence of the files will prevent automated generation attempts.

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
| ingress.path | string | `"/omnigroupserver/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/omnigroupserver/service/"` | Ingress controller path for service connections.  Empty string to disable. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"3057"` | port service will serve ACI connections on |
| additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| annotations | object | `{}` | Additional annotations applied to deployment/statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide omnigroupserver.cfg |
| idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"omnigroupserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"25.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| labels | object | `{}` | Additional labels applied to all objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":30}` | container livenessProbe settings |
| name | string | `"idol-omnigroupserver"` | used to name deployment, service, ingress |
| oauthToolConfigMap | string | `""` | if specified, is the name of a ConfigMap that is expected to provide oauth_tool.cfg. It will be mounted at /etc/config/oauth and used by oauth_tool.exe to generate necessary OAuth configuration. Be aware that this WILL NOT WORK if the OAuth workflow requires user interaction. If this is the case, the OAuth workflow must be conducted elsewhere and the resulting files mounted into the Omnigroupserver container at the expected places for your configuration. |
| ogsStorageClass | string | `"idol-ogs-storage-class"` | Name of the storage class used to provision a PersistentVolume for each OmniGroupServer instance. The associated PVCs are named index-{name}-{pod number} |
| ogsVolumeSize | string | `"2Gi"` | Size of the PersistentVolumeClaim that is created for each OmniGroupServer instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisify the claims made for the desired number of OmniGroupServer instances. |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| servicePort | string | `"3058"` | port service will serve service connections on |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| workingDir | string | `"/omnigroupserver"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)