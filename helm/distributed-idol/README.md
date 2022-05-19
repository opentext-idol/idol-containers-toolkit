# distributed-idol Helm chart
A Helm chart for managing deployments of distributed IDOL systems in a Kubernetes cluster. This chart deploys a DAH, DIH, and a set of Content engines which can autoscale with demand.The chart can deploy in mirror-mode (autoscaling to fulfil query demand) or in non-mirror mode (autoscaling to fulfil index demand) depending on the `setupMirrored` helm value. The default is non-mirror mode. See the [MicroFocus documentation](https://www.microfocus.com/documentation/idol/) for more details on these components.

Once deployed, the DAH and DIH ACI ports will be available at `http://<ingress address>/dah` and `http://<ingress address>/dih`, and the DIH index port will be available
at `http://<ingress address>/index`. 

## Prerequisites

* A Kubernetes cluster satisfying the cluster requirements (see below)
* The `helm` command line tool
* The `kubectl` command line tool

## Required Values
There are some values that are required but do not have defaults. The user of this Helm chart must provide these values via either the `--set`/`--set-file`/`--set-string` or `--values` flags in helm commands:
* `licenseServerIp`: the IP address of the LicenseServer containing the license key required to run the IDOL components in this chart.
* `licenseServerPort`: the port of the LicenseServer containing the license key required to run the IDOL components in this chart.

## Required Kubernetes Secrets
* `dockerhub-secret` : for pulling images from Docker Hub
* `cm-adapter-serving-certs` : contains a TLS certificate and private key

By default the Helm chart is configured to pull images from Docker Hub and expects a Kubernetes secret called `dockerhub-secret` to be created. This secret must contain the credentials required to pull images from Docker Hub. This can be done by substituting a username and API token for Docker Hub into 
```
kubectl create secret docker-registry dockerhub-secret --docker-username=${DOCKERHUB_USER} --docker-password=${DOCKERHUB_APITOKEN}
```
In practice (at present), access to the IDOL images on dockerhub is restricted to the user `microfocusidolreadonly`, so this will be the value of `${DOCKERHUB_USER}` in the example.

If a different name is required for this Kubernetes secret, override the `imagePullSecrets` list value.

The `cm-adapter-serving-certs` secret used by the custom metrics adapter can be generated given certificate and key files by e.g.
`kubectl create secret generic cm-adapter-serving-certs --from-file=serving.crt --from-file=serving.key`
See the `certgen` directory for a helper script to generate these.

## Optional Values
There are some values that are optional or sometimes overriden:
* `httpProxy`: the URL of a HTTP proxy that the installation will have to use to access the external internet. If not set, no http proxying is configured.
* If a private repository is specified for pulling the IDOL images (i.e. by overriding `idolImageRegistry`) then `imagePullSecrets` will also require the name of a Kubernetes secret holding the credentials for pulling from this private repository.

## Cluster requirements
* The cluster must provide a PersistentVolume that can satisfy a PersistentVolumeClaim requesting `contentVolumeSize` (see values.yaml for default) space for each Content engine scheduled to run in the cluster. These PersistentVolumes are where the Content indexes will be stored. These Content engines run within StatefulSets (named "idol-child-content-primary" and "idol-child-content" by default) and are scaled by a HorizontalPodAutoscaler (named "child-content-autoscaler" by default).
* The cluster must provide a further PersistentVolume with `ReadWriteMany` access mode and `contentVolumeSize` space (see the "backup-archive-pvc" PersistentVolumeClaim). One Content engine is designated as the "primary" Content engine (running in the StatefulSet named "idol-child-content-primary" by default). This PersistentVolume is where the primary Content engine stores index commands and backups so that new Content mirrors can quickly initialise. Note that while most volume providers support the `ReadWriteOnce` access mode required by the Content indexes, the `ReadWriteMany` mode has more limited support - see [this table](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for one overview.
* The cluster must provide an [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). For example on a [minikube](https://minikube.sigs.k8s.io/docs/) cluster, one can [enable an NGINX controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/) and see the exposed address using `kubectl get ingress`.
* The cluster must satisfy the requirements of the [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deployment, e.g. Kubelet certificates need to be signed by the cluster certificate authority

## Install
Once the above requirements are satisfied, build the dependencies with
`helm dependency build`
Then the chart can be installed using `helm install` e.g. from this directory, using a name of 'idolrelease' for the release
`helm install -f values.yaml --set licenseServerIp=<license server ip> --set-string licenseServerPort=<license server port> idolrelease .`

## Uninstall
Simply use `helm uninstall` with the release name, e.g. 
`helm uninstall idolrelease`