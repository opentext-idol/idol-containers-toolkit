# idol-nifi

![Version: 0.9.2](https://img.shields.io/badge/Version-0.9.2-informational?style=flat-square) ![AppVersion: 24.4.0](https://img.shields.io/badge/AppVersion-24.4.0-informational?style=flat-square)

Provides a scaleable IDOL NiFi cluster instance (NiFi, NiFi Registry and ZooKeeper).

> Full documentation for IDOL NiFi Ingest available from https://www.microfocus.com/documentation/idol/IDOL_24_4/NiFiIngest_24.4_Documentation/Help/

## Related Documentation

* https://nifi.apache.org/
* https://zookeeper.apache.org/

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://kubernetes-sigs.github.io/metrics-server | metrics-server | 3.8.2 |
| https://prometheus-community.github.io/helm-charts | prometheus | 25.0 |
| https://prometheus-community.github.io/helm-charts | prometheus-adapter | 4.2.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | 0.14.2 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | 0.4.0 |

## Deploying a flow into NiFi

There are two methods for deploying a flow in a Nifi cluster:

* Manually creating a flow once the NiFi cluster has been deployed by specifying no flows to be deployed in the NiFi cluster.

```
nifi:
  flows: []
```

* Naming an existing flow (or multiple flows) within NiFi Registry to deployed. Specify the name of the NiFi Registry bucket, and flow within that bucket, to create a version controlled process group within NiFi from. To deploy a specific version of the flow from NiFi Registry a version can optionally be specified. When not specified or the value is empty, the latest version of the flow is deployed.

```
nifi:
  flows:
  - name: "My Flow"
    bucket: "my-bucket"
  - name: "My Other Flow"
    bucket: "my-bucket"
    version: "2"
```

To update the version of a flow deployed into NiFi, there are two methods:

* Manually upload a new version of the flow into NiFi Registry, and then use the NiFi UI (https://nifi.apache.org/docs/nifi-docs/html/user-guide.html#change-version), APIs (https://nifi.apache.org/docs/nifi-docs/rest-api/index.html) or CLI (https://nifi.apache.org/docs/nifi-docs/html/toolkit-guide.html#nifi_CLI) to update the version of flow used by the deployed process group.
* Re-install the helm template for the NiFi cluster. Persistent Volume Claims are created for the NiFi and NiFi Registry instances deployed by the template, meaning that the template can be re-installed without losing its state. When a flow is deployed using the second method above, if there is an existing process group for the flow to be deployed, but the current version of that process group does not match the desired version, the version used by the process group is updated to the specified version.

## Pre-populating NiFi Registry with buckets and flows

Specify names of the NiFi Registry buckets to be created, and optionally the location of JSON flow files to be imported into the bucket.

```
nifiRegistry:
  buckets:
  - name: "my-bucket"
    flowfiles: []
  - name: "my-other-bucket"
    flowfiles:
    - "/flows/flow1.json"
    - "/flows/flow2.json"
```

## Scaling NiFi

When `nifi.autoScaling.enabled` is set to `true`, some considerations must be made in order for the NiFi cluster to usefully scale.

* `Load Balance Strategy` on NiFi connections - When creating a NiFi flow, connections can be configured to load balance across the NiFi cluster (see https://nifi.apache.org/docs/nifi-docs/html/user-guide.html#Load_Balancing ). Some connections in the NiFi flow must be configured to a value other than `Do not load balance` to enable NiFi FlowFiles to be distributed across the cluster. Setting the `Load Balance Strategy` to `Round Robin` for some connections is recommended for even load balancing.

* Scaling metrics specified in `nifi.autoScaling.metrics` - When autoscaling NiFi, appropriate metrics must be chosen for effective scaling. Values.yaml specifies two scaling metrics by default:
    * Total number of FlowFiles queued, per NiFi cluster node - If there are more than 20,000 FlowFiles queued (on average) per NiFi cluster node, this will cause the NiFi cluster to scale up.
    * Average queue utilization, per NiFi cluster node - If the queue utilization exceeds 25% (on average) per NiFi cluster node, this will cause the NiFi cluster to scale up.

  These metrics can be used as is, with custom limits, or you can specify your own scaling metrics based upon any Prometheus metric(s).

To run a NiFi cluster, you may need to use an external database for storing state information. Many NiFi Ingest processors need to store state information. For example, IDOL Connectors store information about what they have retrieved from a data repository. This information needs to be in an external database so that it is accessible to all of the nodes in the cluster. Configure the connection to your database server by creating a database service. When you configure the IDOL connectors in your data flow, set the property `State Database Service` to the name of the database service that you created.

The files that your connectors download from your data repositories must also be accessible to all of the nodes in a cluster. When you configure your connectors, set the property `adv:IngestSharedPath` to a location, such as a shared folder, that is accessible from all of the nodes in the cluster. Alternatively, set the property `adv:FlowFileEmbedFiles` to `TRUE`, so that the binary file content is included in the FlowFiles created by the connector.

## Deploying multiple NiFi clusters

Multiple NiFi clusters can be deployed from a single helm install command by specifying nifiClusters in the provided values.yaml, e.g.
```
    nifiClusters:
    - clusterId: nf1
    - clusterId: nf2
```
Each NiFi cluster will, by default, be accessible at [hostname]/[clusterId]/nifi and can communicate with each other by using http://[clusterId]:8080/nifi as the instance url when configuring remote process groups.

Each cluster will use parameters from the nifi section by default, but can be overridden in the nifiClusters entry.

Alternatively, this helm chart can be installed multiple times. In this case, the first deployment should deploy nifi registry, prometheus, metrics-server etc, and any further deployments should specify:
```
nifi:
  registryHost: [existing-deployment-name]-reg
nifiRegistry:
  enabled: false
prometheus:
  enabled: false
prometheus-adapter:
  enabled: false
metrics-server:
  enabled: false
```
Each deployment will require a unique name, and ingress points should be manually specified such that they do not conflict. NiFi clusters can communicate with each other by using http://[name]:8080/nifi as the instance url when configuring remote process groups.

## Values

### Globals

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolOemLicenseSecret | string | `""` | Optional Secret containing OEM licensekey.dat and versionkey.dat files for licensing.  Mounted at /nifi/licensekey.dat and /nifi/versionkey.dat |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullPolicy | string | `""` | Global override value for idolImage.imagePullPolicy, has no effect if it is empty or is removed |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| additionalVolumeMounts | list | `[]` | Additional PodSpec VolumeMount (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1) |
| additionalVolumes | list | `[]` | Additional PodSpec Volume (see https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes) |
| annotations | object | `{}` | Additional annotations applied to statefulset (https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"enabled":true,"privileged":false}` | container security context definition  See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-container |
| envConfigMap | string | `""` | Optional configMap name holding extra environnment variables for container |
| idol-licenseserver.enabled | bool | `false` | whether to deploy an IDOL LicenseServer service abstraction |
| idol-licenseserver.licenseServerPort | string | `"20000"` | the ACI port of the IDOL LicenseServer (or abstraction) |
| idol-licenseserver.licenseServerService | string | `"idol-licenseserver"` | the hostname of the IDOL LicenseServer (or abstraction) |
| idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.repo | string | `"nifi-full"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| idolImage.version | string | `"24.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| indexserviceACIPort | string | `"9070"` | the ACI port of the indexing IDOL component |
| indexserviceName | string | `"idol-index-service"` | the hostname of the indexing IDOL component |
| ingressBasicAuthData | string | `"YWRtaW46JGFwcjEkSDY1dnBkTU8kMXAxOGMxN3BuZVFUT2ZjVC9TZkZzMQo="` | base64 encoded htpasswd https://httpd.apache.org/docs/2.4/misc/password_encryptions.html. Default is admin/admin |
| ingressClassName | string | `""` | Optional, https://kubernetes.io/docs/concepts/services-networking/ingress/#the-ingress-resource, applied to all ingress objects |
| ingressProxyBodySize | string | `"2048m"` | the maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| ingressType | string | `"nginx"` | setup ingress for that controller type. Valid values are nginx, haproxy (used by OpenShift) or custom |
| labels | object | `{}` | Additional labels applied to objects (https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) |
| metrics-server.args[0] | string | `"--kubelet-insecure-tls"` |  |
| metrics-server.enabled | bool | `true` | whether to deploy a metrics server instance |
| name | string | `"idol-nifi"` | used to name statefulset, service, ingress |
| nifi.autoScaling.enabled | bool | `true` | deploy a horizontal pod autoscaler for the nifi statefulset |
| nifi.autoScaling.maxReplicas | int | `8` | the maximum size of the nifi statefulset |
| nifi.autoScaling.metrics | list | See below | one or more metrics controlling the horizontal pod autoscaler (https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2/#HorizontalPodAutoscalerSpec) |
| nifi.autoScaling.metrics[0] | object | `{"pods":{"metric":{"name":"nifi_percent_used_count_avg"},"target":{"averageValue":25,"type":"AverageValue"}},"type":"Pods"}` | Scale up if the average queue utilization per nifi node is greater than 25% |
| nifi.autoScaling.metrics[1] | object | `{"pods":{"metric":{"name":"nifi_amount_items_queued_total"},"target":{"averageValue":20000,"type":"AverageValue"}},"type":"Pods"}` | Scale up if there are more than 20000 queued items per nifi node |
| nifi.autoScaling.minReplicas | int | `1` | the minimum size of the nifi statefulset |
| nifi.autoScaling.stabilizationWindowSeconds | int | `300` | no. of seconds a limit must be exceed before scaling the nifi statefulset |
| nifi.dataVolume.storageClass | string | `"idol-nifi-storage-class"` | Name of the storage class used to provision a PersistentVolume for each NiFi instance. The associated PVCs are named statedata-{name}-{pod number} |
| nifi.dataVolume.volumeSize | string | `"16Gi"` | Size of the PersistentVolumeClaim that is created for each NiFi instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisify the claims made for the desired number of NiFi instances. The size chosen here provides a hard limit on the size of the NiFi data storage in each NiFi instance. |
| nifi.flows | list | `[{"bucket":"default-bucket","name":"Basic IDOL","version":""}]` | The flow definitions to import into NiFi registry. Specify the file, registry bucket name (will be created if not found), and whether to import the flow as a process group into NiFi, or specify the name, bucket name (and optionally version, latest will be used if not specified) of an existing flow in NiFi Registry. Customized flows can be added via a custom NiFi image or mounted into the pod (see `additionalVolumes` and `additionalVolumeMounts`) |
| nifi.ingress.aciHost | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifi.ingress.aciTLS | object | `{"crt":"","key":"","secretName":""}` | Whether aci ingress uses TLS. You must set an ingress aciHost to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls |
| nifi.ingress.aciTLS.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.aciTLS.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.aciTLS.secretName | string | `""` | The name of the secret for aci ingress tls. Leave empty if not using TLS. |
| nifi.ingress.annotations | object | `{}` | optional ingress annotations |
| nifi.ingress.enabled | bool | `true` | whether to deploy ingress for nifi |
| nifi.ingress.host | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifi.ingress.metricsHost | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifi.ingress.metricsTLS | object | `{"crt":"","key":"","secretName":""}` | Whether metrics ingress uses TLS. You must set an ingress metricsHost to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls |
| nifi.ingress.metricsTLS.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.metricsTLS.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.metricsTLS.secretName | string | `""` | The name of the secret for metrics ingress tls. Leave empty if not using TLS. |
| nifi.ingress.proxyHost | string | `""` | optional nifi.web.proxy.host value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties) |
| nifi.ingress.proxyPath | string | `""` | optional nifi.web.proxy.context.path value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#web-properties) |
| nifi.ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls |
| nifi.ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| nifi.ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| nifi.jvmMemoryRatio | float | `0.5` | What proportion of the pod memory to allocate for JVM usage |
| nifi.keystorePassword | string | `""` | optional nifi.security.keystorePasswd value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#security_properties) Setting this value is recommended. If it is not set, it will default to a generated value |
| nifi.registryHost | string | `""` | optional hostname of an existing nifi registry instance. Defaults to the created registry instance when nifiRegistry.enabled=true |
| nifi.resources | object | `{"limits":{"cpu":"4000m","memoryMi":10240},"requests":{"cpu":"2000m","memoryMi":4096}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |
| nifi.resources.limits.memoryMi | int | `10240` | memory limit in mebibytes (value used in jvm memory calculation) |
| nifi.resources.requests.memoryMi | int | `4096` | memory requested in mebibytes (value used in jvm memory calculation) |
| nifi.sensitivePropsKey | string | `""` | optional nifi.sensitive.props.key value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#nifi_sensitive_props_key) Setting this value is recommended. If it is not set, it will default to a generated value |
| nifi.truststorePassword | string | `""` | optional nifi.security.truststorePasswd value (see https://nifi.apache.org/docs/nifi-docs/html/administration-guide.html#security_properties) Setting this value is recommended. If it is not set, it will default to a generated value |
| nifiClusters | list | `[{}]` | nifi cluster instances. Each cluster instance inherits values from the nifi section. When more than one cluster is specified, setting a clusterId is required |
| nifiRegistry.buckets | list | `[{"flowfiles":["/scripts/flow-basic-idol.json"],"name":"default-bucket"}]` | Buckets to create. Specify the bucket name, and a list of flow files to populate the bucket with. Customized flows can be added via a custom NiFi Registry image or mounted into the pod (see `additionalVolumes` and `additionalVolumeMounts`) |
| nifiRegistry.dataVolume.storageClass | string | `"idol-nifi-storage-class"` | Name of the storage class used to provision a PersistentVolume for the NiFi Registry instance. The associated PVCs are named statedata-{name}-reg-{pod number} |
| nifiRegistry.dataVolume.volumeSize | string | `"2Gi"` | Size of the PersistentVolumeClaim that is created for the NiFi Registry instance. The size chosen here provides a hard limit on the size of the NiFi Registry data storage in the NiFi Registry instance. |
| nifiRegistry.enabled | bool | `true` | whether to deploy a nifi registry instance |
| nifiRegistry.ingress.annotations | object | `{}` | optional ingress annotations |
| nifiRegistry.ingress.enabled | bool | `true` | whether to deploy ingress for nifi registry |
| nifiRegistry.ingress.host | string | `""` | optional ingress host https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules |
| nifiRegistry.ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls |
| nifiRegistry.ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| nifiRegistry.ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| nifiRegistry.ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created. |
| nifiRegistry.resources | object | `{"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"200m","memory":"1Gi"}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |
| podSecurityContext | object | `{"enabled":true,"runAsGroup":1000,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}}` | pod security context definition  See https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#set-the-security-context-for-a-pod |
| prometheus | object | Default configuration to support `idol-nifi` autoscaling. See values.yaml for details. | `prometheus` sub-chart configuration Required for auto-scaling.  See https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus |
| prometheus-adapter | object | Default configuration to support `idol-nifi` autoscaling. See values.yaml for details. | `prometheus-adapter` sub-chart configuration Required for auto-scaling.  See https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-adapter |
| serviceAccountName | string | `""` | Optional serviceAccountName for the pods (https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account) |
| usingTLS | bool | `false` | whether ports are configured to use TLS (https). |
| zookeeper.resources | object | `{"limits":{"cpu":"200m","memory":"500Mi"},"requests":{"cpu":"200m","memory":"500Mi"}}` | https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)