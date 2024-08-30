# NOTE
THIS CHART IS DEPRECATED.
To run a basic-idol setup with helm, consider using a deployment which combines the relevant helm charts
(idol-nifi, idol-content, idol-commmunity, etc.), as is done in, e.g., idol-stack.

# IDOL Helm Charts

_Helm_ is a package manager for Kubernetes, a system for automating deployment, scaling, and management of containerized applications.

A Helm _Chart_ defines and aids installation of a Kubernetes application.

This directory contains tools to deploy IDOL on Kubernetes, using Helm:
 * The _charts_ directory contains a Helm Chart to deploy the `basic-idol` container set-up.
 * A python script `kubernetes.py` is provided to automatically run the commands needed to deploy with Helm.

## Prerequisites

You will need to install:
 * [The `kubectl` command-line tool](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
 * [The `helm` command-line tool](https://helm.sh/)
 * Python 3, to use the helper script

You will also need access to a Kubernetes cluster. There are a number of tools available that allow you to create a local cluster for testing.

## Configuration

Helm creates Kubernetes objects by substituting values into templates.
It reads the values from YAML files; you can pass different values files to Helm to control which IDOL components are deployed. Files to enable document security or rich media processing are supplied.

Before deploying, you must edit the `charts/basic-idol/variables/env.values` file to add:
 * The IP of an IDOL License Server that will provide licensing for the system;
 * Authentication to pull the IDOL container images from dockerhub.
   Instructions for doing this are in the file comments.

## Deployment

Before installing the IDOL Helm Chart, you must deploy several configuration files from the `basic-idol` compose set-up to the Kubernetes cluster as `ConfigMap` objects.
You can do this by using Kubernetes' _kustomization_ functionality and the `kustomization.yml` files in various subdirectories of `basic-idol`.
The `kubernetes.py` script invokes the required kustomization commands automatically, depending on your choice of IDOL components to deploy, before running Helm with the correct values files.

To install the base IDOL deployment in the current Kubernetes context:

    python3 kubernetes.py

To delete the deployment, and all associated `ConfigMaps`:

    python3 kubernetes.py --clean

To deploy with IDOL rich media components:

    python3 kubernetes.py --mmap

To deploy with document security enabled (requires you to first edit `charts/basic-idol/variables/document-security.values` to add details of your LDAP server):

    python3 kubernetes.py --documentsecurity
