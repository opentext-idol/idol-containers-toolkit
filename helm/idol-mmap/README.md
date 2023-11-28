# idol-mmap

Provides a deployment of a IDOL MMAP (Media Management and Analysis Platform).

## OpenShift Deployment

In order to comply with constraints OpenShift places on containers, the Container and Pod security contexts of the Bitnami PostgreSQL sub chart need to be disabled.
```
postgresql:
  primary:
    containerSecurityContext:
      enabled: false
    podSecurityContext:
      enabled: false
```