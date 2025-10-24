<!--
BEGIN COPYRIGHT NOTICE
Copyright 2022 - 2025 Open Text.

The only warranties for products and services of Open Text and its affiliates and licensors (“Open Text”) are as may be set forth in the express warranty statements accompanying such products and services. Nothing herein should be construed as constituting an additional warranty. Open Text shall not be liable for technical or editorial errors or omissions contained herein. The information contained herein is subject to change without notice.
END COPYRIGHT NOTICE
-->
# distributed-idol
<!-- omit in toc -->

![Version: 0.13.3](https://img.shields.io/badge/Version-0.13.3-informational?style=flat-square) ![AppVersion: 25.4](https://img.shields.io/badge/AppVersion-25.4-informational?style=flat-square)

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Helm Chart Values](#helm-chart-values)
  - [Required Values](#required-values)
  - [Required Secrets](#required-secrets)
  - [Optional Values](#optional-values)
- [Cluster requirements](#cluster-requirements)
  - [Ingress Controller](#ingress-controller)
  - [Storage Classes and Persistent Volumes](#storage-classes-and-persistent-volumes)
    - [backupArchiveStorageClass](#backuparchivestorageclass)
  - [metrics-server](#metrics-server)
- [Install](#install)
- [Endpoints](#endpoints)
- [Upgrading Knowledge Discovery version](#upgrading-knowledge-discovery-version)
- [Uninstall](#uninstall)

## Overview

A [Helm](https://helm.sh/) chart for managing deployments of distributed Knowledge Discovery systems in a Kubernetes cluster.

This chart deploys a DAH, DIH, and a set of Content engines that can autoscale with demand.
The chart can deploy in mirror-mode (autoscaling to fulfil query demand) or in non-mirror mode
(autoscaling to fulfil index demand) depending on the `setupMirrored` helm value.
The default is non-mirror mode.

> Full documentation for the Knowledge Discovery components is available from
>
> - <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/Content_25.4_Documentation/Help/>
> - <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DAH_25.4_Documentation/Help/>
> - <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DIH_25.4_Documentation/Help/>

## Prerequisites

- A Kubernetes cluster satisfying the [cluster requirements](#cluster-requirements)
- The `helm` command line tool
- The `kubectl` command line tool

## Helm Chart Values

The [values.yaml](values.yaml) file provides configuration options for this chart.
Documentation for the values is located in that file.
Some important values are described in more detail below, and a [full reference](#values) is at the end of this README.

### Required Values

There are some values that are required but do not have defaults. The user of this Helm chart must provide these values via either the
`--set`/`--set-file`/`--set-string` or `--values` flags in helm commands:

- `idol-licenseserver.licenseServerIp`: the IP address of the LicenseServer containing the license key required to run the IDOL components in this chart.

### Required Secrets

- `dockerhub-secret` : for pulling images from Docker Hub

By default the Helm chart is configured to pull images from Docker Hub and expects a Kubernetes secret called `dockerhub-secret` to be created.
This secret must contain the credentials required to pull images from Docker Hub. For example (substituting appropriate values for username
and API token):

```sh
kubectl create secret docker-registry dockerhub-secret
    --docker-username=${DOCKERHUB_USER}
    --docker-password=${DOCKERHUB_APITOKEN}
```

In practice (at present), access to the Knowledge Discovery images on dockerhub is restricted to the user `microfocusidolreadonly`, so this will be the
value of `${DOCKERHUB_USER}` in the example.

If a different name is required for this Kubernetes secret, override the `global.imagePullSecrets` list value.

### Optional Values

There are some values that are optional or sometimes overriden:

- `global.http_proxy`/`global.https_proxy`: the URL of a proxy that the installation will have to use to access the external internet. If not set, no http proxying
  is configured.
- If a private repository is specified for pulling the Knowledge Discovery images (e.g. by overriding `global.idolImageRegistry`) then `global.imagePullSecrets` will also
  require the name of a Kubernetes secret holding the credentials for pulling from this private repository.

## Cluster requirements

### Ingress Controller

The cluster must provide an [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). For example on
a [minikube](https://minikube.sigs.k8s.io/docs/) cluster, you can [enable an NGINX controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/)
and see the exposed address using `kubectl get ingress`.

By default the chart is setup ingress for `nginx`. If you are deploying on OpenShift/OKD then you should set `ingress.type=haproxy` and specify
your `ingress.host`.

### Storage Classes and Persistent Volumes

This system uses [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/#introduction) to provide
[Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) as persistent storage for the DIH and Content components.

> Note: uninstalling does not delete the PersistentVolumeClaims. If you redeploy the helm chart, it reuses any existing PV or PVCs.

| [values.yaml](values.yaml)        | default value              | purpose
| ---                               | ---                        | ---
| content.contentStorageClass       | idol-content-storage-class | Content component index and configuration
| dih.dihStorageClass               | idol-dih-storage-class     | DIH component data and configuration
| content.backupArchiveStorageClass | idol-backup-archive-sc     | mirror-mode Content backups. See [backupArchiveStorageClass](#backuparchivestorageclass)

#### backupArchiveStorageClass

In mirror-mode, the cluster must provide a storage class (named "idol-backup-archive-sc" by default) that can provision a PersistentVolume with
`ReadWriteMany` access mode and `contentVolumeSize` space (see the "backup-archive-pvc" PersistentVolumeClaim). One Content engine is designated
as the "primary" Content engine (running in the StatefulSet named "idol-content-primary" by default). This PersistentVolume is where the primary
Content engine stores index commands and backups so that new Content mirrors can quickly initialize. Note that while most volume providers support the `ReadWriteOnce` access mode required by the Content indexes, the `ReadWriteMany` mode has more limited support - see [this table](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for one overview.

### metrics-server

The cluster must satisfy the requirements of the [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deployment. For example,
Kubelet certificates need to be signed by the cluster certificate authority

## Install

After you satifsy the requirements, build the dependencies with
`helm dependency build`

Then you can install the chart by using 'helm install'. For example, from this directory, using a name of 'idolrelease' for the release:

```sh
helm install -f values.yaml
    --set-string idol-licenseserver.licenseServerIp=<license server ip>
    idolrelease .
```

## Endpoints

After you have deployed the helm chart, you can access the following endpoints through ingress:

- `http://<ingress address>/dah/` - The DAH ACI port
- `http://<ingress address>/dih/` - The DIH ACI port
- `http://<ingress address>/index/` - The DIH index port
 
You can optionally expose individual Content engine ACI ports at `http://<ingress address>/content-N/` - see `content.ingress.exposedContents` in
[values.yaml](values.yaml)

## Upgrading Knowledge Discovery version

To upgrade to a newer version of Knowledge Discovery, use a `helm upgrade` command. Note that you must provide the number of Content engines currently
deployed. For example:

```sh
helm upgrade --reuse-values
    --set-string global.idolVersion=<new_version>
    --set-string content.initialEngineCount=<current engine count>
    --set-string autoscaling.minReplicas=<current engine count>
    <release name> <dir containing helm chart>
```

This example redeploys new versions of the DAH, DIH, and Content, which replace the existing ones.

## Uninstall

Use `helm uninstall`

```sh
helm uninstall <release_name>
```

If you no longer require the PVCs, you can manually delete them:

```sh
# delete individually
kubectl delete pvc <pvc_name>
# or delete all matching by label
kubectl delete pvc --selector app.kubernetes.io/instance=<release_name>
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| @kubernetes-sigs | metrics-server | 3.8.2 |
| @prometheus | prometheus | 25.0 |
| @prometheus | prometheus-adapter | 4.2.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-library | ~0.15.0 |
| https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm | idol-licenseserver | ~0.5.0 |

## Values

### Globals

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.http_proxy | string | `""` | Any required http_proxy settings relating to external network access |
| global.https_proxy | string | `""` | Any required https_proxy settings relating to external network access |
| global.idolImageRegistry | string | `""` | Global override value for idolImage.registry |
| global.idolOemLicenseSecret | string | `""` | Optional Secret containing OEM licensekey.dat and versionkey.dat files for licensing |
| global.idolVersion | string | `""` | Global override value for idolImage.version |
| global.imagePullPolicy | string | `""` | Global override value for idolImage.imagePullPolicy, has no effect if it is empty or is removed |
| global.imagePullSecrets | list | `["dockerhub-secret"]` | Global secrets used to pull container images |
| global.no_proxy | string | `""` | Any required no_proxy settings relating to external network access |

### Other Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| autoscaling.enabled | bool | `true` | Enable automatic scaling of the number of Content instances. See maxDocumentCount for non-mirror mode or autoscalingTargetAverageCpuUse for mirror With autoscalingEnabled=false, you can scale using:  kubectl scale statefulset <contentName> --replicas=<N> In a non-mirrored setup, you should redistribute the data before scaling down - see the DREREDISTRIBUTE documentation |
| autoscaling.maxDocumentCount | string | `"5000"` | Corresponds to [Server]::MaxDocumentCount Content configuration parameter Used in non-mirror mode |
| autoscaling.maxReplicas | string | `"6"` | Maximum number of Content instances. |
| autoscaling.minReplicas | string | `"2"` | Minimum number of Content instances. Ignored in non-mirror-mode |
| autoscaling.targetAverageCpuUse | string | `"500m"` | Target CPU use of the Content instances. See metrics.containerResource.target.averageValue in https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/horizontal-pod-autoscaler-v2beta2/#HorizontalPodAutoscalerSpec Used in mirror mode |
| content.aciPort | string | `"9100"` | port service will serve ACI connections on |
| content.additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| content.additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| content.backupArchiveStorageClass | string | `"idol-backup-archive-sc"` | Name of the storage class used to provision the persistent volume for the mirror-mode Content engine backups and index command archive. It is available to all Content engines. It must support the ReadWriteMany AccessMode: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes |
| content.containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| content.containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| content.contentStorageClass | string | `"idol-content-storage-class"` | Name of the storage class used to provision a PersistentVolume for each Content instance. The associated PVCs are named index-{name}-{pod number} |
| content.contentVolumeSize | string | `"16Gi"` | Size of the PersistentVolumeClaim that is created for each Content instance. The Kubernetes cluster will need to provide enough PersistentVolumes to satisfy the claims made for the desired number of Content instances. The size chosen here provides a hard limit on the size of the Content index in each Content instance. |
| content.envConfigMap | string | `""` | Optional configMap name holding extra environment variables for content container |
| content.existingConfigMap | string | `""` | Optional configMap mounted at /etc/config/idol and expected to provide content.cfg and content_primary.cfg |
| content.idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| content.idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| content.idolImage.repo | string | `"content"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| content.idolImage.version | string | `"25.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| content.indexPort | string | `"9101"` | port service will serve index connections on |
| content.ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overridden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| content.ingress.className | string | `""` | Optional parameter to override the default ingress class |
| content.ingress.enabled | bool | `true` | Create ingress resource |
| content.ingress.exposedContents | int | `0` | Allows ingress access to individual content engines. Set to max number of engines to expose |
| content.ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| content.ingress.indexPath | string | `"/index/"` | Ingress controller path for index connections. Empty string to disable. |
| content.ingress.path | string | `"/content/"` | Ingress controller path for ACI connections. |
| content.ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| content.ingress.servicePath | string | `"/content/service/"` | Ingress controller path for service connections. Empty string to disable. |
| content.ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| content.ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| content.ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| content.ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| content.ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| content.initialEngineCount | string | `"1"` | Number of Content engines created on startup. After startup the Content engine autoscaling kicks in and controls the number of Content engines.  The minimum valid value of initialEngineCount is 1. For an upgrade, you must specify the number of Content engines that were present. |
| content.name | string | `"idol-content"` | used to name statefulset, service, ingress |
| content.podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| content.podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| content.primaryBackupInterval | string | `"0"` | corresponds to the [Schedule]::BackupInterval Content configuration parameter. https://www.microfocus.com/documentation/idol/IDOL_12_12/Content_12.12_Documentation/Help/#Configuration/Schedule/BackupInterval.htm%3FTocPath%3DConfiguration%2520Parameters%7CSchedule%7C_____7 |
| content.primaryBackupTime | string | `"02:00"` | corresponds to the [Schedule]::BackupTime Content configuration parameter. https://www.microfocus.com/documentation/idol/IDOL_12_12/Content_12.12_Documentation/Help/#Configuration/Schedule/BackupTime.htm%3FTocPath%3DConfiguration%2520Parameters%7CSchedule%7C_____11 |
| content.resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| content.resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| content.servicePort | string | `"9102"` | port service will serve service connections on |
| content.usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| content.workingDir | string | `"/content"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |
| dah.aciPort | string | `"9060"` | port service will serve ACI connections on |
| dah.additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| dah.additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| dah.containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| dah.containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| dah.envConfigMap | string | `""` | Optional configMap name holding extra environment variables for dah container |
| dah.existingConfigMap | string | `""` | Optional configMap expected to provide dah.cfg |
| dah.idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| dah.idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dah.idolImage.repo | string | `"dah"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dah.idolImage.version | string | `"25.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dah.ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overridden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| dah.ingress.className | string | `""` | Optional parameter to override the default ingress class |
| dah.ingress.enabled | bool | `true` | Create ingress resource |
| dah.ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| dah.ingress.path | string | `"/dah/"` | Ingress controller path for ACI connections. |
| dah.ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| dah.ingress.servicePath | string | `"/dah/service/"` | Ingress controller path for service connections. Empty string to disable. |
| dah.ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| dah.ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| dah.ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| dah.ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| dah.ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| dah.name | string | `"idol-dah"` | used to name statefulset, service, ingress |
| dah.podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| dah.podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| dah.replicas | int | `1` | number of replica pods for this container (defaults to 1) |
| dah.resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| dah.resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| dah.servicePort | string | `"9062"` | port service will serve service connections on |
| dah.usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| dah.workingDir | string | `"/dah"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |
| dih.aciPort | string | `"9070"` | port service will serve ACI connections on |
| dih.additionalVolumeMounts | string | `nil` | Additional PodSpec VolumeMount(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1>) Can be dict of (name, VolumeMount), or list of (VolumeMount). dict form allows for merging definitions from multiple values files. |
| dih.additionalVolumes | string | `nil` | Additional PodSpec Volume(s) (see <https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes>) Can be dict of (name, Volume), or list of (Volume). dict form allows for merging definitions from multiple values files. |
| dih.containerSecurityContext | object | `{"enabled":false,"privileged":false,"runAsNonRoot":true}` | Optional SecurityContext for container (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#securitycontext-v1-core) |
| dih.containerSecurityContext.enabled | bool | `false` | enable SecurityContext for container. Setting to false omits. |
| dih.dihStorageClass | string | `"idol-dih-storage-class"` | Name of the storage class used to provision the persistent volume for the dih configuration and data The associated PVC is named dih-persistent-storage-<name>-0 |
| dih.envConfigMap | string | `""` | Optional configMap name holding extra environment variables for dah container |
| dih.existingConfigMap | string | `""` | Optional configMap expected to provide dih.cfg |
| dih.idolImage.imagePullPolicy | string | `"IfNotPresent"` | used to determine whether to pull the specified image (see https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy) |
| dih.idolImage.registry | string | `"microfocusidolserver"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dih.idolImage.repo | string | `"dih"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dih.idolImage.version | string | `"25.4"` | used to construct container image name: {idolImage.registry}/{idolImage.repo}:{idolImage.version} |
| dih.indexPort | string | `"9071"` | port service will serve index connections on |
| dih.ingress.annotations | object | `{}` | Ingress controller specific annotations Some annotations are added automatically based on ingress.type and other values, but can  be overridden/augmented here e.g. https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations |
| dih.ingress.className | string | `""` | Optional parameter to override the default ingress class |
| dih.ingress.enabled | bool | `true` | Create ingress resource |
| dih.ingress.host | string | `""` | Optional host (see https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-rules). For an OpenShift environment this is required (see https://docs.openshift.com/container-platform/4.11/networking/routes/route-configuration.html#nw-ingress-creating-a-route-via-an-ingress_route-configuration) |
| dih.ingress.metricsPath | string | `"/metrics/"` | Ingress controller path for metrics connections. |
| dih.ingress.path | string | `"/dih/"` | Ingress controller path for ACI connections. |
| dih.ingress.proxyBodySize | string | `"2048m"` | Maximum allowed size of the client request body, defining the maximum size of requests that can be made to IDOL components within the installation, e.g. the amount of data sent in DREADDDATA index commands. The value should be an nginx "size" value. See http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size for the documentation of the corresponding nginx configuration parameter. |
| dih.ingress.servicePath | string | `"/dih/service/"` | Ingress controller path for service connections. Empty string to disable. |
| dih.ingress.tls | object | `{"crt":"","key":"","secretName":""}` | Whether ingress uses TLS. You must set an ingress host to use this.  See https://kubernetes.io/docs/concepts/services-networking/ingress/#tls  |
| dih.ingress.tls.crt | string | `""` | Certificate data value to generate tls Secret (should be base64 encoded) |
| dih.ingress.tls.key | string | `""` | Private key data value to generate tls Secret (should be base64 encoded) |
| dih.ingress.tls.secretName | string | `""` | The name of the secret for ingress TLS. Leave empty if not using TLS.  If specified then either this secret must already exist, or crt and key values must be provided and secret will be created..  |
| dih.ingress.type | string | `"nginx"` | Ingress controller type to setup for. Valid values are nginx or haproxy (used by OpenShift) |
| dih.name | string | `"idol-dih"` | used to name statefulset, service, ingress |
| dih.podSecurityContext | object | `{"enabled":false,"fsGroup":0,"runAsGroup":0,"runAsUser":1000}` | Optional PodSecurityContext (see https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.29/#podsecuritycontext-v1-core) |
| dih.podSecurityContext.enabled | bool | `false` | enable PodSecurityContext. Setting to false omits. |
| dih.resources | object | `{"enabled":false,"limits":{"cpu":"1000m","memory":"1Gi"},"requests":{"cpu":"1000m","memory":"1Gi"}}` | Optional resources for container (see https://kubernetes.io/docs/concepts/configuration/manage-resources-containers) |
| dih.resources.enabled | bool | `false` | enable resources for container. Setting to false omits. |
| dih.servicePort | string | `"9072"` | port service will serve service connections on |
| dih.usingTLS | bool | `false` | whether aci/service/index ports are configured to use TLS (https). If configuring for TLS, then consider setting IDOL_SSL_COMPONENT_CERT_PATH and IDOL_SSL_COMPONENT_KEY_PATH in envConfigMap to provide required TLS certificates |
| dih.workingDir | string | `"/dih"` | Expected working directory for the container. Should only need to change this for a heavily customized image. |
| idol-licenseserver.enabled | bool | `false` | create a cluster service proxying to a LicenseServer instance |
| idol-licenseserver.licenseServerIp | string | `"this must be set to a valid IP address"` | IP address of LicenseServer instance |
| indexserviceName | string | `"idol-index-service"` | internal parameter to specify the index service name. |
| licenseServerHostname | string | `"idol-licenseserver"` | maps to [License] LicenseServerHost in the IDOL cfg files Should point to a resolvable IDOL LicenseServer (or Kubernetes service abstraction - see the idol-licenseserver chart) |
| licenseServerPort | string | `"20000"` | ACI port of the LicenseServer instance |
| metrics-server | object | `{"args":["--kubelet-insecure-tls"],"enabled":true}` | `metrics-server` sub-chart configuration Required if auto-scaling on system metrics (e.g. cpu) Note a cluster can typically only have one metrics-server installed |
| metrics-server.enabled | bool | `true` | whether to deploy a metrics server instance |
| prometheus | object | Default configuration to support `distributed-idol` autoscaling based on DIH fullness ratio. See values.yaml for details. | `prometheus` sub-chart configuration Required for auto-scaling on custom metrics (e.g. DIH fullness) See https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus |
| prometheus-adapter | object | Default configuration to support `distributed-idol` autoscaling based on DIH fullness ratio. See values.yaml for details. | `prometheus-adapter` sub-chart configuration Required for auto-scaling on custom metrics (e.g. DIH fullness) See https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-adapter |
| queryserviceName | string | `"idol-query-service"` | internal parameter to specify the query service name. |
| setupMirrored | bool | `false` | When `true` this will configure the  DAH and DIH in mirror-mode, meaning the Contents will all be mirrors of each other. When `false`, the DAH and DIH will be configured in non-mirror mode, meaning that documents will be distributed between the content engines. In mirror-mode, the Content engines will autoscale to fulfil query demand. In non-mirror-mode, Content engines will autoscale to fulfil index demand. See <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DAH_25.4_Documentation/Help/Content/Configuration/Server/MirrorMode.htm> and <https://www.microfocus.com/documentation/idol/knowledge-discovery-25.4/DIH_25.4_Documentation/Help/Content/Configuration/Server/MirrorMode.htm> |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
