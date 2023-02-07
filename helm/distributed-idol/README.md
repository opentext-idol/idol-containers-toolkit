# distributed-idol Helm chart <!-- omit in toc -->

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Required Values](#required-values)
- [Required Kubernetes Secrets](#required-kubernetes-secrets)
- [Optional Values](#optional-values)
- [Cluster requirements](#cluster-requirements)
  - [Ingress Controller](#ingress-controller)
  - [Storage Classes and Persistent Volumes](#storage-classes-and-persistent-volumes)
    - [backupArchiveStorageClass](#backuparchivestorageclass)
  - [metrics-server](#metrics-server)
- [Install](#install)
- [Endpoints](#endpoints)
- [Upgrading IDOL version](#upgrading-idol-version)
- [Uninstall](#uninstall)


## Overview 

A [Helm](https://helm.sh/) chart for managing deployments of distributed IDOL systems in a Kubernetes cluster. 

This chart deploys a DAH, DIH, and a set of Content engines that can autoscale with demand. The chart can deploy in mirror-mode (autoscaling to fulfil query demand) or in non-mirror mode (autoscaling to fulfil index demand) depending on the `setupMirrored` helm value. The default is non-mirror mode. See the [MicroFocus documentation](https://www.microfocus.com/documentation/idol/) for more details on these components.

## Prerequisites

* A Kubernetes cluster satisfying the [cluster requirements](#cluster-requirements)
* The `helm` command line tool
* The `kubectl` command line tool

## Required Values

There are some values that are required but do not have defaults. The user of this Helm chart must provide these values via either the `--set`/`--set-file`/`--set-string` or `--values` flags in helm commands:
* `licenseServerIp`: the IP address of the LicenseServer containing the license key required to run the IDOL components in this chart.
* `licenseServerPort`: the port of the LicenseServer containing the license key required to run the IDOL components in this chart.

## Required Kubernetes Secrets

* `dockerhub-secret` : for pulling images from Docker Hub
* `cm-adapter-serving-certs` : for autoscaling, contains a TLS certificate and private key

By default the Helm chart is configured to pull images from Docker Hub and expects a Kubernetes secret called `dockerhub-secret` to be created. This secret must contain the credentials required to pull images from Docker Hub. This can be done by substituting a username and API token for Docker Hub into 
```
kubectl create secret docker-registry dockerhub-secret 
    --docker-username=${DOCKERHUB_USER} 
    --docker-password=${DOCKERHUB_APITOKEN}
```
In practice (at present), access to the IDOL images on dockerhub is restricted to the user `microfocusidolreadonly`, so this will be the value of `${DOCKERHUB_USER}` in the example.

If a different name is required for this Kubernetes secret, override the `imagePullSecrets` list value.

The `cm-adapter-serving-certs` secret used by the custom metrics adapter can be generated given certificate and key files by e.g.
`kubectl create secret generic cm-adapter-serving-certs --from-file=serving.crt --from-file=serving.key`
See [certgen/README.md](certgen/README.md) directory for a helper script to generate these.

## Optional Values

There are some values that are optional or sometimes overriden:
* `httpProxy`: the URL of a HTTP proxy that the installation will have to use to access the external internet. If not set, no http proxying is configured.
* If a private repository is specified for pulling the IDOL images (i.e. by overriding `idolImageRegistry`) then `imagePullSecrets` will also require the name of a Kubernetes secret holding the credentials for pulling from this private repository.

## Cluster requirements

### Ingress Controller

The cluster must provide an [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). For example on a [minikube](https://minikube.sigs.k8s.io/docs/) cluster, you can [enable an NGINX controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/) and see the exposed address using `kubectl get ingress`.

### Storage Classes and Persistent Volumes

This system uses [Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/#introduction) to provide [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) as persistent storage for the DIH and Content components.

Note: uninstalling does not delete the PersistentVolumeClaims. If you redeploy the helm chart, it reuses any existing PV or PVCs.

| [values.yaml](values.yaml)               | default value              | purpose 
| ---                       | ---                        | --- |
| contentStorageClass       | idol-content-storage-class | Content component index and configuration |
| dihStorageClass           | idol-dih-storage-class     | DIH component data and configuration |
| backupArchiveStorageClass | idol-backup-archive-sc     | mirror-mode Content backups. See [backupArchiveStorageClass](#backuparchivestorageclass) |

#### backupArchiveStorageClass

In mirror-mode, the cluster must provide a storage class (named "idol-backup-archive-sc" by default) that can provision a PersistentVolume with `ReadWriteMany` access mode and `contentVolumeSize` space (see the "backup-archive-pvc" PersistentVolumeClaim). One Content engine is designated as the "primary" Content engine (running in the StatefulSet named "idol-child-content-primary" by default). This PersistentVolume is where the primary Content engine stores index commands and backups so that new Content mirrors can quickly initialize. Note that while most volume providers support the `ReadWriteOnce` access mode required by the Content indexes, the `ReadWriteMany` mode has more limited support - see [this table](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for one overview.

### metrics-server

The cluster must satisfy the requirements of the [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deployment. For example, Kubelet certificates need to be signed by the cluster certificate authority

## Install

After you satifsy the requirements, build the dependencies with
`helm dependency build`

Then you can install the chart by using 'helm install'. For example, from this directory, using a name of 'idolrelease' for the release:

```
helm install -f values.yaml 
    --set licenseServerIp=<license server ip> 
    --set-string licenseServerPort=<license server port> idolrelease .
```

## Endpoints 

After you have deployed the helm chart, you can access the following endpoints through ingress:

* `http://<ingress address>/dah/` - The DAH ACI port
* `http://<ingress address>/dih/` - The DIH ACI port
* `http://<ingress address>/index/` - The DIH index port
  
You can optionally expose individual Content engine ACI ports at `http://<ingress address>/content-N/` - see `exposedContents` in [values.yaml](values.yaml)

## Upgrading IDOL version

To upgrade to a newer version of IDOL, use a `helm upgrade` command. Note that you must provide the number of Content engines currently deployed. For example:

```
helm upgrade --reuse-values 
    --set-string idolVersion=<new_version>
    --set-string initialContentEngineCount=<current engine count>
    --set-string autoscalingMinReplicas=<current engine count>
    <release name> <dir containing helm chart>
```

This example redeploys new versions of the DAH, DIH, and Content, which replace the existing ones.

## Uninstall

Use `helm uninstall` 
```
helm uninstall <release name>
```

If you no longer require the PVCs, you can manually delete them:
```
kubectl delete pvc <pvc name>
```