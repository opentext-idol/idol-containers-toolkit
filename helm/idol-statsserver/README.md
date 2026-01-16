# idol-statsserver

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 25.4](https://img.shields.io/badge/AppVersion-25.4-informational?style=flat-square)

Provides a Knowledge Discovery statsserver deployment. This provides statistics about interactions with other Knowledge Discovery components.

Depends on connections to:

- Knowledge Discovery LicenseServer (`licenseServerHostname`)

The config file can be overridden via `existingConfigMap`.

This chart provides an `idol-statsserver` system.

> Full documentation for statsserver available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/QMS_25.4_Documentation/Help/Content/Appendixes/statsserver>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | ~0.15.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | ~0.5.0 |

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
| ingress.className | string | `""` | Optional parameter to override the default ingress class (has no effect if type is 'gateway') |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.path | string | `"/statsserver/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/statsserver/service/"` | Ingress controller path for service connections. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx, gateway or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"19870"` | port service will serve ACI connections on |
| additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| annotations | object | `{}` | Additional annotations applied to deployment/statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide statsserver.cfg |
| idol-licenseserver.enabled | bool | `true` | whether to deploy the idol-licenseserver sub-chart |
| idol-licenseserver.licenseServerExternalName | string | `"cbgdevdish.swinfra.net"` |  |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"idol-docker-images.svsartifactory.swinfra.net"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"statsserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"25.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.gateway.backendTimeout | string | `""` | Optional, backend timeout for ingress route |
| ingress.gateway.name | string | `""` | Optional, name of the gateway to use for ingress |
| ingress.gateway.namespace | string | `""` | Optional, namespace of the gateway to use for ingress |
| ingress.gateway.requestTimeout | string | `""` | Optional, request timeout for ingress route |
| labels | object | `{}` | Additional labels applied to all objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| licenseServerSSLMethod | string | `"None"` | SSL method for license server connection (None, Negotiate, etc.) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-statsserver"` | used to name deployment, service, ingress |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| replicas | int | `1` | number of replica pods for this container (defaults to 1) |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| servicePort | string | `"19872"` | port service will serve service connections on |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| workingDir | string | `"/statsserver"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)