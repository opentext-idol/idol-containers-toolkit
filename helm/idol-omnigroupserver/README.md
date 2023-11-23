# idol-omnigroupserver

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![AppVersion: 23.4](https://img.shields.io/badge/AppVersion-23.4-informational?style=flat-square)

Provides an IDOL OmniGroupServer deployment.

Whilst this can be deployed 'as-is', it is expected that a real deployment will
require configuration particular to the repositories the OGS instance needs to
provide user/group information for.

Consumers of this chart are encouraged to use this as a subchart, providing an
additional config-map with the OGS config file - see `.Values.existingConfigMap`

> Full documentation for OmniGroupServer available from https://www.microfocus.com/documentation/idol/IDOL_23_4/OmniGroupServer_23.4_Documentation/Help/index.html

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.2.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | 0.1.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| aciPort | string | `"3057"` | port service will serve ACI connections on |
| enableIngress | bool | `true` | Create ingress resource |
| existingConfigMap | string | `""` | if specified, mounted at /etc/config/idol and expected to provide omnigroupserver.cfg |
| idol-licenseserver.enabled | bool | `false` | whether to deploy the idol-licenseserver sub-chart |
| idolImageRegistry | string | `"microfocusidolserver"` | used to construct container image name: {idolImageRegistry}/{image}:{idolVersion} |
| idolVersion | string | `"23.4"` | used to construct container image name: {idolImageRegistry}/{image}:{idolVersion} |
| image | string | `"omnigroupserver"` | used to construct container image name: {idolImageRegistry}/{image}:{idolVersion} |
| imagePullSecrets | list | `["dockerhub-secret"]` | secrets used to pull container images |
| ingressClassName | string | `""` | Optional parameter to override the default ingress class |
| ingressHost | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| ingressType | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| licenseServerHostname | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| name | string | `"idol-omnigroupserver"` | used to name deployment, service, ingress |
| servicePort | string | `"3058"` | port service will serve service connections on |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.11.3](https://github.com/norwoodj/helm-docs/releases/v1.11.3)