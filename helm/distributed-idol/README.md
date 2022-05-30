# distributed-idol Helm chart
The distributed IDOL Helm chart is a Helm chart for managing deployments of distributed IDOL systems in a Kubernetes cluster. This chart deploys a [DAH](https://www.microfocus.com/documentation/idol/IDOL_12_11/DAH_12.11_Documentation/Guides/html/#Introduction/About_the_DAH.htm?TocPath=Use%2520the%2520DAH%257CIntroduction%257CAbout%2520the%2520Distributed%2520Action%2520Handler%257C_____0), [DIH](https://www.microfocus.com/documentation/idol/IDOL_12_11/DIH_12.11_Documentation/Guides/html/#Introduction/About_the_DIH.htm?TocPath=Use%2520the%2520DIH%257CIntroduction%257CAbout%2520the%2520Distributed%2520Index%2520Handler%257C_____0), and a set of [Content](https://www.microfocus.com/documentation/idol/IDOL_12_11/Content_12.11_Documentation/Help/Content/_ACI_Welcome.htm) engines, which can autoscale with demand. You can deploy the chart in mirror-mode (autoscaling to fulfil query demand) or in non-mirror mode (autoscaling to fulfil index demand), by modifying the `setupMirrored` helm value. The default is non-mirror mode. For more details about these components, see the [MicroFocus documentation](https://www.microfocus.com/documentation/idol/).

After you deploy the Helm chart, the DAH and DIH ACI ports are available at `http://<ingress address>/dah` and `http://<ingress address>/dih`, and the DIH index port is available at `http://<ingress address>/index`. 

## Prerequisites

* A Kubernetes cluster that satisfies the cluster requirements (see below)
* The `helm` command line tool
* The `kubectl` command line tool

## Required Values
There are some values that are required but do not have defaults. You must provide these values by setting either the `--set`/`--set-file`/`--set-string` or `--values` flags in helm commands:
* `licenseServerIp`: the IP address of the LicenseServer that contains the license key required to run the IDOL components in this chart.
* `licenseServerPort`: the port of the LicenseServer that contains the license key required to run the IDOL components in this chart.

## Required Kubernetes Secrets
* `dockerhub-secret` : contains credentials for pulling images from Docker Hub
* `cm-adapter-serving-certs` : contains a TLS certificate and private key

By default the Helm chart is configured to pull images from Docker Hub and expects a Kubernetes secret called `dockerhub-secret` to exist. This secret must contain the credentials required to pull images from Docker Hub. You can modify credentials by substituting a username and API token for Docker Hub into: 
```
kubectl create secret docker-registry dockerhub-secret --docker-username=${DOCKERHUB_USER} --docker-password=${DOCKERHUB_APITOKEN}
```
In practice (at present), access to the IDOL images on dockerhub is restricted to the user `microfocusidolreadonly`, so this is the value of `${DOCKERHUB_USER}` in the example.

If you require a different name for this Kubernetes secret, override the `imagePullSecrets` list value.

You can generate the `cm-adapter-serving-certs` secret used by the custom metrics adapter by providing certificate and key files, for example:
`kubectl create secret generic cm-adapter-serving-certs --from-file=serving.crt --from-file=serving.key`
See the `certgen` directory for a helper script to generate these.

## Optional Values
There are some values that are optional or sometimes overriden:
* `httpProxy`: the URL of a HTTP proxy that the installation must use to access the external internet. If not set, no http proxying is configured.
* `imagePullSecrets`: If you specify a private repository for pulling the IDOL images (by overriding `idolImageRegistry`), then `imagePullSecrets` also requires the name of a Kubernetes secret holding the credentials for pulling from this private repository.

## Cluster requirements
* The cluster must provide a PersistentVolume that can satisfy a PersistentVolumeClaim requesting `contentVolumeSize` (see values.yaml for default) space for each Content engine scheduled to run in the cluster. These PersistentVolumes are where the Content indexes are stored. These Content engines run in StatefulSets (named "idol-child-content-primary" and "idol-child-content" by default) and are scaled by a HorizontalPodAutoscaler (named "child-content-autoscaler" by default).
* The cluster must provide a further PersistentVolume with `ReadWriteMany` access mode and `contentVolumeSize` space (see the "backup-archive-pvc" PersistentVolumeClaim). One Content engine is designated as the "primary" Content engine (running in the StatefulSet named "idol-child-content-primary" by default). This PersistentVolume is where the primary Content engine stores index commands and backups so that new Content mirrors can quickly initialise. Note that while most volume providers support the `ReadWriteOnce` access mode required by the Content indexes, the `ReadWriteMany` mode has more limited support - see [this table](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) for one overview.
* The cluster must provide an [IngressController](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/). For example on a [minikube](https://minikube.sigs.k8s.io/docs/) cluster, one can [enable an NGINX controller](https://kubernetes.io/docs/tasks/access-application-cluster/ingress-minikube/) and see the exposed address using `kubectl get ingress`.
* The cluster must satisfy the requirements of the [metrics-server](https://github.com/kubernetes-sigs/metrics-server) deployment, for example Kubelet certificates must be signed by the cluster certificate authority

## Install
After you satisfy the cluster requirements, build the dependencies with:
`helm dependency build`
Then you can install the chart by using `helm install`, for example from this directory, using a name of 'idolrelease' for the release:
`helm install -f values.yaml --set licenseServerIp=<license server ip> --set-string licenseServerPort=<license server port> idolrelease .`

## Uninstall
To uninstall, use `helm uninstall` with the release name, for example:
`helm uninstall idolrelease`