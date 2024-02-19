# idol-eductionserver



![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 24.1](https://img.shields.io/badge/AppVersion-24.1-informational?style=flat-square) 

Provides an IDOL Eduction Server deployment.

Depends on connections to:

- IDOL LicenseServer (`licenseServerHostname`)

The config file can be overridden via `existingConfigMap`.

This chart may be used to provide entity extraction, entity redaction and sentiment analysis functionality.

> Full documentation for Eduction Server available from https://www.microfocus.com/documentation/idol/IDOL_24.1/EductionServer_24.1_Documentation/Help/







## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.4.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"13000"` | port service will serve ACI connections on |
| additionalVolumeMounts | list | `[{"mountPath":"/eductionserver/cfg","name":"grammar-config"}]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[{"configMap":{"name":"pxi-config"},"name":"grammar-config"}]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide community.cfg |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| grammarPackage | string | `"pii"` | the grammar package configuration file to use, must be one of:                -- 'pci', 'phi', 'phi_telephone', 'phi_internet', 'pii', 'pii_telephone' or 'psi'. |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"eductionserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"24.1"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| ingress.className | string | `""` | Optional parameter to override the default ingress class |
| ingress.enabled | bool | `true` | Create ingress resource |
| ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe | object | `{"initialDelaySeconds":120}` | container livenessProbe settings |
| name | string | `"idol-eductionserver"` | used to name deployment, service, ingress |
| servicePort | string | `"13002"` | port service will serve service connections on |

