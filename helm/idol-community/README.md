# idol-community

![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square) ![AppVersion: 24.3](https://img.shields.io/badge/AppVersion-24.3-informational?style=flat-square)

Provides an IDOL Community deployment. By default this will provide basic user
setup suitable to be used to login to IDOL Find.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)
- IDOL Content/Agentstore (`queryserviceName`, `queryserviceACIPort`, `agentStoreName`, `agentStoreACIPort`)

To setup document security you will need to provide your own configuration (see `existingConfigMap`)
and may wish to deploy alongside the _idol-omnigroupserver_ chart.

> Full documentation for Community available from https://www.microfocus.com/documentation/idol/IDOL_24_3/Community_24.3_Documentation/Help/

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.14.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | single-content | 0.10.0 |

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
| ingress.path | string | `"/community/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/community/service/"` | Ingress controller path for service connections. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"9030"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| agentStoreACIPort | string | `"9050"` | agentstore service aci port (maps to Community AgentDRE configuration). |
| agentStoreName | string | `"idol-agentstore"` | agentstore service/hostname (maps to Community AgentDRE configuration). |
| annotations | object | `{}` | Additional annotations applied to deployment/statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| containerSecurityContext | object | `{"enabled":false}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide community.cfg |
| idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"community"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version}. |
| idolImage.version | string | `"24.3"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| labels | object | `{}` | Additional labels applied to all objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| licenseServerHostname | string | `"idol-licenseserver"` | maps to [License] LicenseServerHost in the IDOL cfg files Should point to a resolvable IDOL LicenseServer (or Kubernetes service abstraction - see the idol-licenseserver chart) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":30}` | container livenessProbe settings |
| name | string | `"idol-community"` | used to name deployment, service, ingress |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| queryserviceACIPort | string | `"9060"` | query service aci port (maps to Community DataDRE configuration). |
| queryserviceName | string | `"idol-query-service"` | query service/hostname (maps to Community DataDRE configuration). |
| replicas | int | `1` | number of replica pods for this container (defaults to 1) |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| servicePort | string | `"9032"` | port service will serve service connections on |
| single-content.enabled | bool | `false` | whether to deploy the single-content sub-chart.  You may use this to get a basic Community running by setting the agentStoreName/agentStoreACIPort to the queryserviceName/queryserviceACIPort values. |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)