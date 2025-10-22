# single-content

![Version: 0.11.4](https://img.shields.io/badge/Version-0.11.4-informational?style=flat-square) ![AppVersion: 25.4](https://img.shields.io/badge/AppVersion-25.4-informational?style=flat-square)

Provides a Knowledge Discovery Content statefulset.

Provides `idol-query-service` and `idol-index-service` Service objects, backed by
a single Knowledge Discovery Content instance. Intended as a much lighter-weight alternative to
the `distributed-idol` chart, for use in testing charts that expect one or both
of these endpoints to exist in the cluster.

> Full documentation for Content available from <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/Content_25.4_Documentation/Help/>

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
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.indexPath | string | `"/index/"` | Ingress controller path for index connections. Empty string to disable. |
| ingress.path | string | `"/content/"` | Ingress controller path for ACI connections. |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.servicePath | string | `"/content/service/"` | Ingress controller path for service connections. Empty string to disable. |
| ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"9100"` | port service will serve ACI connections on |
| additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| annotations | object | `{}` | Additional annotations applied to deployment/statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| contentStorageClass | string | `"idol-content-storage-class"` | Name of the storage class used to provision a PersistentVolume for each Content instance. The associated PVCs are named index-{name}-{pod number} |
| contentVolumeSize | string | `"16Gi"` | Size of the PersistentVolumeClaim that is created for each Content instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisify the claims made for the desired number of Content instances. The size chosen here provides a hard limit on the size of the Content index in each Content instance. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for content container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide $IDOL_COMPONENT.cfg                      or content.cfg if $IDOL_COMPONENT is unavailable. |
| idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart. Must set licenseServerIp or licenseServerExternalName if enabled |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"content"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version}. |
| idolImage.version | string | `"25.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexPort | string | `"9101"` | port service will serve index connections on |
| indexserviceACIPort | string | `"9070"` | the port idol-index-service will serve ACI connections on. |
| indexserviceName | string | `"idol-index-service"` | internal parameter to specify the index service name, if this is empty then no                     additional service will be provisioned. |
| labels | object | `{}` | Additional labels applied to all objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| licenseServerHostname | string | `"idol-licenseserver"` | maps to [License] LicenseServerHost in the IDOL cfg files Should point to a resolvable IDOL LicenseServer (or Kubernetes service abstraction - see the idol-licenseserver chart) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| name | string | `"idol-content"` | used to name statefulset, service, ingress |
| podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| queryserviceACIPort | string | `"9060"` | port idol-query-service will serve ACI connections on. |
| queryserviceName | string | `"idol-query-service"` | internal parameter to specify the query service name, if this is empty then no                     additional service will be provisioned. |
| replicas | int | `1` | number of replica pods for this workload (defaults to 1). Consider distributed-idol chart instead if setting a value greater than 1. |
| resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| servicePort | string | `"9102"` | port service will serve service connections on |
| usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| workingDir | string | `"/content"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)