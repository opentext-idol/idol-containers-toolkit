# IDOL Containers Toolkit Helm Charts <!-- omit in toc -->

Helm charts for IDOL

## Table of contents <!-- omit in toc -->

- [Usage](#usage)
- [Common Setup](#common-setup)
  - [IDOL Licensing](#idol-licensing)
    - [LicenseServer based](#licenseserver-based)
    - [OEM based](#oem-based)
  - [Ingress](#ingress)
  - [StorageClass](#storageclass)
- [License](#license)

## Usage

```sh
# Add the repository
helm repo add idol-containers-toolkit https://raw.githubusercontent.com/opentext-idol/idol-containers-toolkit/main/helm
# List available charts
helm search repo idol-containers-toolkit
```

Refer to individual chart `README.md` files for configuration details.

## Common Setup

Most of the charts use the [idol-library](idol-library) library chart to implement common
handling of Helm values across the charts.

[idol-library-example-test](idol-library-example-test/README.md) shows these common values.

> N.B. The examples shown below use Helm's `--set` to configure values for clarity. It is recommended that these settings should be provided via a file e.g. `--set-file custom.values.yaml`

### IDOL Licensing

#### LicenseServer based

```sh
# Using an external licenseserver instance directly
helm install --set licenseServerHostname=my-licenseserver \
    --set-string licenseServerPort=20000 \
    my-deployment idol-containers-toolkit/single-content
```

or see [idol-licenseserver](idol-licenseserver/README.md) for installing a Kubernetes Service abstraction.

#### OEM based

```sh
# Create a secret containing oem licensekey.dat and versionkey.dat
kubectl create secret generic idol-oem-license \
    --from-file=licensekey.dat=/path/to/oem.licensekey.dat \
    --from-file=versionkey.dat=/path/to/versionkey.dat

# Deploy a chart using that secret
helm install --set global.idolOemLicenseSecret=idol-oem-license \
    my-deployment idol-containers-toolkit/single-content
```

### Ingress

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) controls access to
services from outside the Kubernetes cluster. Exact configuration of Ingress varies from cluster
to cluster.

Most of the charts present a common set of ingress control values under the `ingress:` values.yaml key.

```sh
# Example configuring some ingress settings
helm install --set ingress.className=nginx \
    --set ingress.host=my-external-hostname \
    my-deployment idol-containers-toolkit/single-content

# Example running chart with ingress disabled
# i.e. services within cluster can access but not external
helm install --set ingress.enabled=false \
    my-deployment idol-containers-toolkit/single-content
```

### StorageClass

A number of the charts (e.g. [idol-nifi](idol-nifi/README.md), [single-content](single-content/README.md))
make use of [Kubernetes Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
for storage.

This is handled by configuring a [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/) name in the chart.

```sh
# Example setting up single-content with the right storage class name for a microk8s cluster
helm install --set contentStorageClass=microk8s-hostpath \
    my-deployment idol-containers-toolkit/single-content
```

## License

[MIT License](../LICENSE)
