# single-content

![Version: 0.3.0](https://img.shields.io/badge/Version-0.3.0-informational?style=flat-square) ![AppVersion: 23.4.0](https://img.shields.io/badge/AppVersion-23.4.0-informational?style=flat-square)

Provides an IDOL Content statefulset.

Provides `idol-query-service` and `idol-index-service` Service objects, backed by
a single IDOL Content instance. Intended as a much lighter-weight alternative to
the `distributed-idol` chart, for use in testing charts that expect one or both
of these endpoints to exist in the cluster.

> Full documentation for Content available from https://www.microfocus.com/documentation/idol/IDOL_23_4/Content_23.4_Documentation/Help/

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.4.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | 0.1.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"9100"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| contentStorageClass | string | `"idol-content-storage-class"` | Name of the storage class used to provision a PersistentVolume for each Content instance. The associated PVCs are named index-{name}-{pod number} |
| contentVolumeSize | string | `"16Gi"` | Size of the PersistentVolumeClaim that is created for each Content instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisify the claims made for the desired number of Content instances. The size chosen here provides a hard limit on the size of the Content index in each Content instance. |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for content container |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide content.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| idol-licenseserver.enabled | bool | `true` | whether to deploy the idol-licenseserver sub-chart |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"content"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"23.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexPort | string | `"9101"` | port service will serve index connections on |
| indexserviceACIPort | string | `"9070"` | the port idol-index-service will serve ACI connections on. |
| indexserviceName | string | `"idol-index-service"` | internal parameter to specify the index service name. |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | maps to [License] LicenseServerHost in the IDOL cfg files Should point to a resolvable IDOL LicenseServer (or Kubernetes service abstraction - see the idol-licenseserver chart) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| name | string | `"idol-content"` | used to name statefulset, service, ingress |
| queryserviceACIPort | string | `"9060"` | port idol-query-service will serve ACI connections on. |
| queryserviceName | string | `"idol-query-service"` | internal parameter to specify the query service name. |
| servicePort | string | `"9102"` | port service will serve service connections on |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.3](https://github.com/norwoodj/helm-docs/releases/v1.11.3)