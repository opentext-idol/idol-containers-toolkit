# IDOL NiFi Connector Management — Helm chart <!-- omit in toc -->

Deploys the IDOL Connector Management API, and optionally the NiFi instance it drives and the
PostgreSQL database it stores state in.

Every object is named `<release>-<name>` (`<release>-idol-connector-management` by default), so
several releases can coexist in one namespace. `fullnameOverride` replaces the generated name
if you need a specific one.

## Table of contents <!-- omit in toc -->

- [Quick start](#quick-start)
- [Deployment scenarios](#deployment-scenarios)
  - [1. Existing NiFi and PostgreSQL](#1-existing-nifi-and-postgresql)
  - [2. Complete stack](#2-complete-stack)
  - [3. Connector resources from a volume](#3-connector-resources-from-a-volume)
- [Database](#database)
- [Credentials and Secrets](#credentials-and-secrets)
- [Connector resources](#connector-resources)
- [Common configuration](#common-configuration)
- [Health probes](#health-probes)
- [Metrics](#metrics)
- [Running the tests](#running-the-tests)
- [Upgrading](#upgrading)
- [Changing settings on a running deployment](#changing-settings-on-a-running-deployment)
- [Uninstalling and cleaning up](#uninstalling-and-cleaning-up)
- [Production checklist](#production-checklist)
- [Known limitations](#known-limitations)
- [IDOL licensing](#idol-licensing)
- [Bundling the DocumentSecurity API](#bundling-the-documentsecurity-api)

# Quick start

```sh
helm install ncm . --wait

helm test ncm --logs
```

The defaults deploy the API, a bundled PostgreSQL, a bundled NiFi and an empty resources volume —
enough to come up healthy with no values file at all, in about a minute on a warm node.

The images default to the published, version-tagged artifacts in
`cs-knowledgediscovery-docker-dev`, so nothing needs overriding to get started. Add
`-f values-dev.yaml` to run local docker builds instead.

**It comes up empty.** The resources volume is provisioned blank, so `/v1/types/*` lists nothing
and no connector can be created yet. Either populate that volume or point the API at a resource
repository instead — both are in [Connector resources](#connector-resources), and the install
notes print the options with your release's names filled in.

Database passwords and NiFi's sensitive-properties key are generated on first install.

Read [Production checklist](#production-checklist) before exposing this to anyone.

# Deployment scenarios

## 1. Existing NiFi and PostgreSQL

The API only, pointed at infrastructure you already run.

```yaml
postgresql:
  enabled: false                      # do not deploy the bundled database
externalPostgresql:
  host: postgres.example.com
  database: idol_connector_management
  username: ncm
  password: <password>                # or use existingSecret - see below

nifi:
  enabled: false                      # do not deploy the bundled NiFi

connectorManagement:
  nifi:
    endpoint: http://nifi.example.com:8080/nifi
    username: <user>                  # if your NiFi requires authentication
    password: <password>
```

Both `enabled` flags default to **true**, so this scenario is the one that needs them turned off.
Turning off `nifi` without setting `connectorManagement.nifi.endpoint` fails the render rather than
installing something that can never become ready.

The API reaches NiFi over its REST API, so the endpoint must be reachable from the cluster.

**NiFi 2.7 or later is required.** Several standard processors used by the flows the API builds
renamed properties in 2.7, so on 2.6 or earlier every connector deploys with validation errors and
none can start. The API refuses such an endpoint outright: `/v1/health/ready` stays `503` and names
the version it found, rather than letting the problem surface one connector at a time. The bundled
NiFi is 2.9, so this only applies when pointing at your own.

When `username` and `password` are set, the API exchanges them for a NiFi access token and renews
it before it expires, so a long-running deployment does not need restarting when the token's
lifetime runs out. Both values belong in a Secret rather than in `values.yaml` — see
[Credentials and Secrets](#credentials-and-secrets).

### Verifying the NiFi certificate <!-- omit in toc -->

An `https://` endpoint connects with no further configuration, but **by default the certificate is
not verified** — any certificate from any issuer is accepted. The connection is encrypted while the
server is not authenticated, which is fine for a NiFi reached over a network you control and not
much use against one you do not. The default is what it is for backwards compatibility; turn
verification on for anything beyond a trusted network:

```yaml
connectorManagement:
  nifi:
    endpoint: https://nifi.example.com:8443/nifi
    tls:
      verify: true
      existingCaSecret: nifi-ca        # Secret holding the certificate to trust
      caKey: ca.crt                    # its key; also the filename in the container
```

`caKey` decides how the file is read: a `.p12`, `.pfx` or `.jks` extension is loaded as a trust
store — supply its password with `trustStorePassword`, or better,
`existingTrustStorePasswordSecret` — and anything else as PEM, which is what a Kubernetes Secret
or cert-manager issuer normally hands you. Only the named key is mounted, so a Secret that also
holds a private key does not expose it to the container. `existingCaConfigMap` works the same way
when the certificate lives in a ConfigMap.

With `verify: true` and no CA configured, the JVM's default trust store is used — enough for a
certificate issued by a public CA, or one already installed in the image. A missing file,
unreadable trust store or wrong password fails the pod's startup with the filename in the message,
rather than quietly falling back to an unverified connection.

`verifyHostname: false` keeps the certificate check but drops the check that the certificate names
the host in `endpoint` — the setting for a trusted certificate issued for a different name, which
is common when reaching a service by an address its certificate does not list.

TLS 1.3 and 1.2 are both offered, with the floor set by the JVM's own policy, so a NiFi requiring
either version works. Mutual TLS does not: the API cannot present a client certificate, so a NiFi
that requires one is unreachable — authenticate with `username`/`password` instead.

## 2. Complete stack

Everything in-cluster: API, NiFi, PostgreSQL, and optionally DocumentSecurity. The first three are
the defaults, so only DocumentSecurity has to be asked for.

```yaml
documentsecurity:
  enabled: true                       # only if connectors use the Groups operation
```

Each component deploys its own `postgresql-ha`, which is simpler to reason about at the cost of
a second StatefulSet (roughly 1 CPU and 1.5GB). To run DocumentSecurity against this chart's
database instead:

```yaml
documentsecurity:
  enabled: true
  postgresql:
    enabled: false                                                # no second database
  externalPostgresql:
    host: '{{ .Release.Name }}-postgresql-pgpool'
    database: idol-connector-management
    username: postgres                                            # match postgresql.postgresql.username
    existingSecret: '{{ .Release.Name }}-postgresql-credentials'   # this chart's Secret
```

Both values are templated by the DocumentSecurity chart, so the release name resolves at render
time and this works from a static values file. Sharing is safe: the two schemas do not overlap —
DocumentSecurity owns users, groups, repositories and update state, this chart owns connectors,
targets, jobs and reports — and DocumentSecurity creates its tables idempotently rather than
through the versioned scheme described under [Upgrading](#upgrading).

## 3. Connector resources from a volume

A volume is provisioned by default, but empty — see
[Connector resources](#connector-resources) for the ways to fill it. In short, either point at a
claim you have already populated:

```yaml
connectorManagement:
  resourcesVolume:
    existingClaim: connector-resources
    readOnly: true
```

or keep the provisioned volume and fill it from Artifactory or Google Cloud Storage with the
`seeded` storage provider. A deployment that reads a repository directly needs no volume at all —
set `resourcesVolume.enabled=false` in that case.

# Database

The API stores every connector, target, job and report in PostgreSQL, and the bundled NiFi uses
the same instance. You must configure one of the two options below — **the chart refuses to
render without it**.

> The container image falls back to an embedded HSQLDB file when given no connection string.
> That file lives in the container's writable layer with no volume behind it, so the API would
> start, pass its readiness probe, and lose all state on the next restart. The chart fails the
> render rather than let that happen silently.

## Bundled PostgreSQL <!-- omit in toc -->

The default. The `postgresql-ha` sub-chart is deployed, and its passwords are generated on first
install — see [Credentials and Secrets](#credentials-and-secrets).

```yaml
postgresql:
  enabled: true
```

## Existing (external) PostgreSQL <!-- omit in toc -->

Disable the sub-chart and describe the instance under `externalPostgresql`:

```yaml
postgresql:
  enabled: false
  jdbcParameters: "sslmode=require"   # appended to the JDBC URL; leading "?" optional
externalPostgresql:
  host: my-instance.abc123.eu-west-1.rds.amazonaws.com
  port: 5432
  database: idol_connector_management
  username: ncm
  password: <password>
```

The two blocks are separate on purpose: everything under `postgresql` configures the bundled
sub-chart (`postgresql.enabled`, the credential Secret and `jdbcParameters` aside), while
`externalPostgresql` describes an instance this chart does not deploy. The
`idol-documentsecurity` sub-chart splits them the same way.

`database`, `username` and `password` fall back to the `postgresql.postgresql.*` values if left
empty. The database must already exist and the user must be able to create tables in it — the
API creates and migrates its own schema on startup.

Both the API and the bundled NiFi get a `wait-for-postgres` init container, so the pods stay in
`Init` until the database answers.

## Supplying the connection string directly <!-- omit in toc -->

For a database this chart does not model:

```yaml
connectorManagement:
  env:
    CONNECTORS_STATE_PROVIDER_DATABASE_CONNECTIONSTRING: "jdbc:postgresql://host:5432/db"
    CONNECTORS_STATE_PROVIDER_DATABASE_USERNAME: "user"
    CONNECTORS_STATE_PROVIDER_DATABASE_PASSWORD: "password"
```

This takes over the whole database block, so supply all three together. It does **not** work with
the bundled NiFi, which is on by default: NiFi needs a host and port it can resolve, not a JDBC
URL, so this path also needs `nifi.enabled=false` and an external NiFi. Note the password is then
in a ConfigMap — prefer `externalPostgresql.existingSecret`.

# Credentials and Secrets

No credential is rendered into a ConfigMap. Four Secrets are involved:

| Secret | Contents | Generated? |
|---|---|---|
| `<release>-postgresql-credentials` | `password`, `repmgr-password`, `admin-password` | yes, when the database is bundled |
| `<release>-<nifi.name>-sensitive-props` | `sensitive-props-key` | yes, 32 characters |
| `<release>-documentsecurity-credentials` | `password` | yes, when DocumentSecurity deploys its own database |
| `<release>-<name>-env` | `connectorManagement.secretEnv` plus `NIFI_PASSWORD`, and the NiFi trust-store password when one is set inline | no |

Generated values are created on first install and **preserved across upgrades**. Every generated
credential Secret carries `helm.sh/resource-policy: keep`, because the data they protect outlives
`helm uninstall` — see [Uninstalling and cleaning up](#uninstalling-and-cleaning-up).

NiFi's sensitive-properties key encrypts every `enc{...}` value in its flow, including the
database credentials the bundled flow holds. **Changing it after first install makes the existing
flow undecryptable**: NiFi will fail to start or ghost the affected components, and recovery
means re-keying with NiFi's own tooling or discarding the flow and re-entering every connector
credential.

## Using your own Secrets <!-- omit in toc -->

Generation relies on Helm's `lookup`, which reads the cluster. Two consequences:

- **Never deploy with `helm template | kubectl apply`.** `lookup` returns nothing without a
  cluster connection, so every apply would generate fresh credentials and rotate them.
- **Under Argo CD or Flux, do not rely on generation.** They render without cluster access by
  default, so the values would change on every sync. Supply your own Secrets instead:

```yaml
nifi:
  existingSensitivePropsSecret: my-nifi-props   # key: sensitive-props-key

connectorManagement:
  nifi:
    existingSecret: my-nifi-api-credentials
    existingSecretUsernameKey: username
    existingSecretPasswordKey: password
```

The database Secret depends on which database is in use, and the two are **not**
interchangeable — for the bundled one, the sub-chart has to be handed the same Secret, and the
key names are bitnami's:

```yaml
postgresql:
  existingSecret: my-db-credentials      # keys: password, repmgr-password, admin-password
  postgresql:
    existingSecret: my-db-credentials
  pgpool:
    existingSecret: my-db-credentials
```

For an external instance it needs only a password, optionally a username, with keys named to
suit:

```yaml
postgresql:
  enabled: false
externalPostgresql:
  host: postgres.example.com
  existingSecret: my-db-credentials
  existingSecretPasswordKey: password
  existingSecretUsernameKey: username    # empty keeps the username in the ConfigMap
```

Setting the external key names alongside the bundled database fails the render rather than being
silently ignored, since bitnami would not read them. The chart likewise fails the render if the
three bundled values disagree, rather than letting PostgreSQL and the API read different Secrets.

Use something like External Secrets or sealed-secrets to populate them.

The chart cannot read a Secret it does not create, so rotating a value *inside* a user-managed
Secret does not restart the API. Run `kubectl rollout restart statefulset/<release>-<name>` after
rotating. For the database password, restart NiFi as well: it takes its database credentials from
the same Secret, and applies them when it starts — see
[Changing settings on a running deployment](#changing-settings-on-a-running-deployment).

## Other sensitive values <!-- omit in toc -->

Anything secret that would otherwise go in `connectorManagement.env` belongs in `secretEnv`,
which is rendered into a Secret instead of the ConfigMap:

```yaml
connectorManagement:
  secretEnv:
    CONNECTORS_STORAGE_PROVIDER_GOOGLECLOUD_PRIVATEKEY: "-----BEGIN PRIVATE KEY-----..."
```

To keep secrets out of values entirely, leave `secretEnv` empty and use
`connectorManagement.envFrom` with your own `secretRef`.

# Connector resources

Connector, target and processing types are not built into the image — the API reads them from a
storage provider at runtime, and **a default install has none of them**. This section is the step
that turns a healthy deployment into a usable one.

By default the chart provisions an empty 2Gi volume
(`connectorManagement.resourcesVolume.enabled=true`) and an init container creates the directory
layout on it. That is what lets a default install pass its readiness check, but the volume stays
empty until you do one of the following:

| Option | Use when | Set |
|--------|----------|-----|
| **Populate the volume yourself** | you have a resource set to copy in, or a pre-loaded claim to mount | nothing, or `resourcesVolume.existingClaim` |
| **Seed the volume from a repository** | you want the chart to fill it on first start and serve locally afterwards | `CONNECTORS_STORAGE_PROVIDER_TYPE=seeded` |
| **Read a repository directly** | you would rather not manage a volume at all | `CONNECTORS_STORAGE_PROVIDER_TYPE=artifactory` or `googlecloud` |

The last one makes the volume redundant — set `resourcesVolume.enabled=false` with it, and give
the cache an `emptyDir` via `CONNECTORS_STORAGE_PROVIDER_CACHE_DIR`.

## The layout the filesystem provider expects <!-- omit in toc -->

Four categories under `/opt/nifi-connector-management/resources` (or wherever
`CONNECTORS_STORAGE_PROVIDER_FILESYSTEM_DIRECTORY` points):

```
connectors/<Type>/<version>/...        e.g. connectors/Web/27.1.0-nifi2/...
targets/<Type>/<version>/...
processing/<Type>/<version>/...
NARs/<artifactId>/<version>/<artifactId>-<version>.nar
```

`connectors/` must exist or readiness fails with `Resource directory not found: connectors/` and
the pod never becomes Ready. **`NARs/` is not checked at all**, which makes omitting it the more
dangerous mistake: the pod becomes Ready, the catalogue lists, and deployment then fails whenever a
flow needs one of the shared component NARs. Populate all four.

A connector's own NAR is not among them — it lives beside its manifest under
`connectors/<Type>/<version>/`. `NARs/` carries the shared components (keyview, eduction,
scripting, indexing, viewer and the like) that any flow may reference.

The chart's init container creates all four directories on a provisioned volume; on an
`existingClaim` they are yours to create, because the claim's contents are never touched by the
chart.

To fill the provisioned volume by hand, copy a resource set into it — through a temporary pod that
mounts `resources-<release>-<name>-0`, or with `kubectl cp` into the running API pod — then either
`POST /v1/admin/resources/resync` or restart the pod, so the cached listings are dropped. Adding
types to a running deployment is covered in
[Adding connectors to a running deployment](#adding-connectors-to-a-running-deployment).

**With a claim you populate yourself** — the option to use for a shared, pre-loaded volume:

```yaml
connectorManagement:
  resourcesVolume:
    existingClaim: connector-resources
    readOnly: true
```

The claim must already exist in the release namespace. `storageClass`, `size` and `accessModes`
are ignored on this path.

**With the chart-provisioned volume** — the default — an `init-resource-dirs` container creates the
bare layout so the API starts cleanly with no resources present, ready to be filled. Usually only
the size needs attention:

```yaml
connectorManagement:
  resourcesVolume:
    size: 2Gi                    # a full connector set is much larger - NARs alone run to
                                 # hundreds of MB each
```

To fill it, use the `seeded` storage provider, which copies from another provider on startup and
needs `readOnly: false`:

```yaml
connectorManagement:
  env:
    CONNECTORS_STORAGE_PROVIDER_TYPE: seeded
    CONNECTORS_STORAGE_PROVIDER_SEEDED_SOURCE: artifactory
    CONNECTORS_STORAGE_PROVIDER_SEEDED_TARGET: filesystem
    CONNECTORS_STORAGE_PROVIDER_SEEDED_SEEDMODE: skip    # skip (default), update, or overwrite
```

The source provider's own configuration comes too — for `artifactory` that is
`CONNECTORS_STORAGE_PROVIDER_ARTIFACTORY_BASEURL`, `_PLATFORM`, and the `_CONNECTOR_TYPES`,
`_TARGET_TYPES`, `_PROCESSING_TYPES` and `_NAR_TYPES` lists with their per-type overrides;
`docker/bootstrapper/bootstrapper.properties` is a worked example of the whole set.

Seeding runs in the background: the pod starts promptly but stays **not ready** until the copy
finishes, and the `/v1/types/*` endpoints answer 503 meanwhile. On an empty volume that takes
minutes, so `helm install --wait` needs a `--timeout` to match. See
[Health probes](#health-probes) for the measured numbers and the retry policy.

Alternatively skip the volume entirely and read directly from `artifactory` or `googlecloud`,
with `CONNECTORS_STORAGE_PROVIDER_CACHE_DIR` set — the chart then backs that path with an
`emptyDir`, so the cache is rebuilt after each pod replacement but needs no storage.

## Serving a directory from the node <!-- omit in toc -->

For development, where you want the API to read connectors you have just built on the machine
running the cluster. There is no dedicated value for this: mount the directory with the generic
`additionalVolumes` / `additionalVolumeMounts` pair and point the provider at it.

```yaml
additionalVolumes:
  - name: local-connectors
    hostPath:
      path: /run/desktop/mnt/host/c/dev/resources   # Docker Desktop form of C:\dev\resources
      type: Directory
additionalVolumeMounts:
  - name: local-connectors
    mountPath: /opt/local-connectors
    readOnly: true
connectorManagement:
  env:
    CONNECTORS_STORAGE_PROVIDER_TYPE: filesystem
    CONNECTORS_STORAGE_PROVIDER_FILESYSTEM_DIRECTORY: /opt/local-connectors
```

Single-node clusters only — a `hostPath` resolves on whichever node the pod lands on.

**Mount it at a path of its own, not over `/opt/nifi-connector-management/resources`.** Two
volumes on one path is invalid, but Kubernetes only rejects it when the pod is created, so the
install succeeds and then runs no pods at all. The chart checks for this and fails the render
instead.

Giving the local directory its own path also lets it sit *alongside* a remote repository rather
than replacing it, via the `composite` provider — resources resolve against the children in
order, so a locally built connector shadows the published one of the same type and version while
everything else still comes from Artifactory:

```yaml
connectorManagement:
  env:
    CONNECTORS_STORAGE_PROVIDER_TYPE: composite
    CONNECTORS_STORAGE_PROVIDER_COMPOSITE_PROVIDERS: "filesystem,artifactory"
    CONNECTORS_STORAGE_PROVIDER_FILESYSTEM_DIRECTORY: /opt/local-connectors
```

Each child reads its own `CONNECTORS_STORAGE_PROVIDER_<TYPE>_*` settings, so the Artifactory
configuration above applies unchanged. Two children of the same type are not supported.

## Adding connectors to a running deployment <!-- omit in toc -->

Publish the new resources where the deployment reads them — a new version in your Artifactory or
GCS repository, or a new directory on the resources volume — then tell the API to look again:

```sh
curl -X POST http://<host>/v1/admin/resources/resync
```

```json
{ "state": "SEEDING", "resourcesAvailable": true, "category": "connectors", "filesCopied": 3 }
```

Two things happen. A `seeded` provider copies whatever the source has gained, in the background and
under its seed mode — so with the default `skip` the cost is proportional to what is new. And the
cached type definitions and listings are dropped, so a resource that is already in place appears
without waiting for a cache to expire.

Serving continues throughout: readiness stays up, and the catalogue answers from the resources
already available. `state` is `SEEDING` while a copy is running and `SEEDED` when there was nothing
to copy; `resourcesAvailable` is false only while the very first copy is still running. A request
made while a copy is already running reports that copy rather than starting a second.
`/v1/health/ready` carries the progress. The endpoint requires cloud admin privileges when
authentication is enabled.

Without calling it, changes are still picked up eventually: listings expire after 60s
(`CONNECTORS_STORAGE_PROVIDER_CACHE_LISTING_TTL`) and type definitions after
`connectors.types.cache.ttl.seconds` (default 600s).

**Publish new versions rather than patching existing ones.** A `type/version` directory is several
files, and nothing makes their arrival atomic — on any writable provider. Each file is published
atomically, and the manifest is copied last so a resolvable version is a complete one, but a version
overwritten in place can still be read mid-update. Cached content is also keyed by path, so bytes
republished under a path that already existed keep serving from cache until the content TTL expires.
A new version has neither problem.

# Common configuration

**Images.** `connectorManagement.image` and `nifi.image` are full references. `global.imageRegistry`
applies **only** to the bitnami `postgresql-ha` sub-charts, which is what its default
(a dockerhub mirror) is for. `global.imagePullPolicy` applies to every container this chart and
the DocumentSecurity sub-chart create; a per-component `imagePullPolicy` overrides it. The
exception is the `postgresql-ha` sub-charts, which have no global pull-policy value of their own
and stay on `IfNotPresent` — set `postgresql.postgresql.image.pullPolicy` and
`postgresql.pgpool.image.pullPolicy` if you need to change those.

**Storage classes.** `global.defaultStorageClass` applies to every PVC the chart and its
sub-charts create; a per-volume `storageClass` overrides it. Empty means no `storageClassName` is
set, so the cluster's default applies — correct for most clusters.

**Service accounts.** `serviceAccountName` is the chart-wide default;
`connectorManagement.serviceAccountName` and `nifi.serviceAccountName` override it per pod.
Prefer the per-component values when binding a cloud identity: a shared account gives every pod
the union of what any of them needs, and the NiFi pod runs connector code, headless Chrome and
`ExecuteDocumentLua`/`Python`. The pods set `automountServiceAccountToken: false`; GKE Workload
Identity, EKS IRSA and Azure Workload Identity are unaffected.

**Ingress and TLS.** Set `connectorManagement.ingress.host` and, for TLS, either reference a
Secret that already exists:

```yaml
connectorManagement:
  ingress:
    enabled: true
    host: ncm.example.com
    tls:
      secretName: ncm-tls          # e.g. issued by cert-manager
```

or have the chart create it by supplying `crt` and `key` as well. TLS terminates at the ingress:
the container serves plain HTTP on 8080 (public) and 8081 (internal callbacks).
`connectorManagement.ingress.internalEnabled` publishes the internal API too and should stay
`false` unless you have a specific reason.

# Health probes

| Endpoint | Used by | Reports |
|---|---|---|
| `/v1/health/live` | startup and liveness probes | that the application is running; no dependencies |
| `/v1/health/ready` | readiness probe | database and NiFi always required; resource provider and key store required only until each has first answered |

The split matters. A dependency outage fails **readiness**, so the pod is removed from the
Service until it recovers, without restarting. An unrecoverable startup failure — a refused
database schema, bad configuration — fails the **startup** probe, and after its budget the
container is killed, so the pod enters `CrashLoopBackOff` with the reason in
`kubectl logs --previous` rather than sitting at `0/1 Running` indefinitely.

**The startup budget is `failureThreshold` × `periodSeconds`** — 180 seconds by default — and it
has to cover everything the API does before it serves its first request. The knob exists for a slow
image pull or a cold JVM on constrained hardware; raise it if a pod is being killed before it can
answer at all.

Seeding is deliberately **not** part of that budget. A `seeded` provider copies its resource set on
a background thread, so the web application starts within seconds and the startup probe is
satisfied immediately, while **readiness** reports the service unavailable until the copy finishes:

```
$ curl -s localhost:8080/v1/health/ready | jq -c '.checks[] | select(.name=="ResourceProvider")'
{"name":"ResourceProvider","status":"DOWN",
 "data":{"error":"populating resources from the seed source (attempt 1, connectors, 47 copied so far)"}}
```

The pod therefore sits `0/1 Running` with the reason in the readiness body rather than
CrashLoopBackOffing its way through a long download, and `helm install --wait` waits for the seed
instead of racing it — give it a `--timeout` that covers the copy. Measured on an empty volume
seeding the three connectors, three targets, fourteen processing types and six NARs of
`docker/bootstrapper/bootstrapper.properties`: **~550MB in about six minutes**. Subsequent boots
find the volume populated and become ready in seconds.

While seeding is in progress the `/v1/types/*` endpoints answer **503** with a `Retry-After` rather
than serving a partial catalogue, since a half-copied resource set lists successfully and would
otherwise look complete.

A failed copy is retried with a doubling delay — by default ten attempts, 10s doubling to a 60s
ceiling, so roughly seven minutes of source downtime is survived without intervention. A retry
resumes rather than restarts. Tune it through `connectorManagement.env` when your source needs
longer:

```yaml
connectorManagement:
  env:
    CONNECTORS_STORAGE_PROVIDER_SEEDED_RETRY_ATTEMPTS: "20"
    CONNECTORS_STORAGE_PROVIDER_SEEDED_RETRY_DELAY_SECONDS: "10"
    CONNECTORS_STORAGE_PROVIDER_SEEDED_RETRY_DELAY_MAX_SECONDS: "60"
```

Once the attempts are exhausted the readiness check reports the failure and the pod stays out of
rotation — nothing restarts it, because liveness is deliberately shallow, so a permanently broken
source needs a fix and a `kubectl rollout restart`.

# Metrics

`GET /internal/metrics` serves the Prometheus text exposition format on the **internal port (8081)**.
It is on by default.

```yaml
connectorManagement:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: false        # needs the Prometheus Operator CRDs
      interval: 30s
      scrapeTimeout: 10s
```

**Do not route this through the public ingress.** The figures are cross-tenant aggregates — one
series counts every tenant's connectors — so exposing 8081 to anyone who can reach the public
ingress shows each tenant the shape of every other tenant's deployment. The endpoint answers `403`
on port 8080, and the `port-isolation` test asserts it; `ingress-internal.yaml` is the only thing
that should ever expose 8081, and only to a network you control.

## With the Prometheus Operator <!-- omit in toc -->

Set `connectorManagement.metrics.serviceMonitor.enabled=true`. The chart creates a `ServiceMonitor`
selecting its own Service and scraping the `http-internal` port. If the
`monitoring.coreos.com` CRDs are not installed the render succeeds but the install fails with
`no matches for kind "ServiceMonitor"` — which is why it defaults to off.

## Without the Operator <!-- omit in toc -->

Add a scrape config to your Prometheus:

```yaml
scrape_configs:
  - job_name: idol-connector-management
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: [<your-namespace>]
    scheme: http
    metrics_path: /internal/metrics
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        regex: <release>-idol-connector-management
        action: keep
      - source_labels: [__meta_kubernetes_pod_container_port_number]
        regex: "8081"
        action: keep
```

## NiFi's metrics <!-- omit in toc -->

The bundled NiFi serves its own Prometheus metrics - flow, queue, processor and JVM figures - at
`/nifi-api/flow/metrics/prometheus` on its HTTP port (8080), and its pod carries the same
`prometheus.io/*` annotations as the api, so anything scraping on those collects both. Turn the
annotations off with `nifi.metrics.enabled=false`. The figures name every flow component, and
component names carry tenant and entity ids, so they need the same care as the api's.

## The bundled Prometheus <!-- omit in toc -->

`prometheus.enabled=true` deploys a Prometheus (the prometheus-community chart) for a cluster with no
monitoring of its own. It watches this release and nothing else, so any number of releases can each
run one:

- **One scrape job**, named after the release, over pods in the release's namespace that carry this
  release's `app.kubernetes.io/instance` label and a `prometheus.io/scrape` annotation - the api and
  NiFi. The sub-chart's own jobs (API server, nodes, cadvisor, every annotated pod and service in
  every namespace) are replaced.
- **No cluster-wide exporters.** node-exporter (a DaemonSet on host port 9100, which a second
  release could not start), kube-state-metrics, the pushgateway and alertmanager are off.
- **Namespaced permissions.** The sub-chart's ClusterRole is not created; the chart grants the
  server `get`/`list`/`watch` on pods in the release namespace only (`prometheus-rbac.yaml`).

Node and cluster metrics are therefore not collected; they belong to the cluster's own monitoring.
Any of the above can be turned back on through the `prometheus.*` sub-chart values - setting
`prometheus.rbac.create=true` restores the sub-chart's cluster-wide role, and the chart's own Role is
then not created.

## Reading the metrics <!-- omit in toc -->

```promql
# ingestion throughput
sum by (operation) (rate(ncm_documents_total{outcome="processed"}[5m]))

# failure ratio — alert above 1%
sum(rate(ncm_documents_total{outcome=~"failed|errored"}[5m]))
  / sum(rate(ncm_documents_total[5m]))

# configured but not running
sum by (type) (ncm_connectors{enabled="true",deployment_status!="enabled"})
```

# Running the tests

```sh
helm test <release> --logs
```

Five suites, each conditional on what it checks, and each run as a Pod named
`<release>-<name>-test-<suite>`:

| Suite | Checks |
|-------|--------|
| `health` | The API's own readiness, plus the database, NiFi and resource provider it depends on |
| `api-contract` | The connector, target and processing type endpoints return their catalogues |
| `nifi` | The bundled NiFi is serving, through both its routable Service and the pod DNS name the API uses |
| `port-isolation` | `/v1/*` is refused on the internal port and `/internal/*` on the public one |
| `auth` | A protected endpoint refuses an unauthenticated caller while the health endpoints stay exempt — only when `connectorManagement.auth.enabled=true`. No token is minted, so it proves rejection, not acceptance |

Set `tests.enabled=false` to omit them all.

A green run prints `Phase: Succeeded` for every suite and exits 0. The summary is listed
alphabetically, not in the order the suites ran — `health` runs first, and `auth`, when enabled,
runs last:

```
TEST SUITE:  <release>-idol-connector-management-test-api-contract    Phase: Succeeded
TEST SUITE:  <release>-idol-connector-management-test-health          Phase: Succeeded
TEST SUITE:  <release>-idol-connector-management-test-nifi            Phase: Succeeded
TEST SUITE:  <release>-idol-connector-management-test-port-isolation  Phase: Succeeded
```

`--logs` then appends each suite's output, in run order, under a `POD LOGS:` heading.

Three things to know:

- **Helm stops at the first failing hook.** Later suites are not run, and `helm status` then
  shows their *previous* result. Compare `Last Started` timestamps before believing a phase.
- **Trust the exit code over a skim of the output.** Each assertion prints its own `PASS`/`FAIL`
  line, so a run with failures still prints plenty of `PASS`. A failing suite leaves its pod
  `Error`; read the whole log with
  `kubectl logs <release>-<name>-test-<suite> -n <namespace>`.
- **The pods are kept deliberately.** They are not deleted on success, because `--logs` reads them
  after the hook finishes. Each run replaces the previous pod of the same name.

## Cleaning up after a test run <!-- omit in toc -->

Because the pods are kept, a finished run leaves up to five `Completed` pods in the namespace, and
they outlive `helm uninstall`. They share a label that no other object carries, so they can be
removed on their own, leaving the release itself untouched and running:

```sh
kubectl delete pod -l app=<release>-<name>-test -n <namespace>
```

That is `app=<release>-idol-connector-management-test` with the default naming, or
`app=<fullnameOverride>-test` if you set one. Nothing depends on the pods being there, so clearing
them is optional housekeeping — worth doing before reading logs from a *new* run so there is no
doubt which pod you are looking at. To remove the release and its data as well, see
[Uninstalling and cleaning up](#uninstalling-and-cleaning-up).

# Upgrading

**Take a database backup first.**

```sh
kubectl exec <postgres-pod> -- env PGPASSWORD=$(kubectl get secret <release>-postgresql-credentials \
    -o jsonpath='{.data.password}' | base64 -d) \
    pg_dump -U <user> -d <database> > backup.sql
```

The API records a schema version in the `schemaversion` table and reconciles it on startup:

- **Same version** — nothing happens.
- **A newer version than the running build**, i.e. a rollback — start-up **fails** and the schema
  is left untouched. Redeploy the newer image, or restore a backup.
- **An older version with a registered migration** — migrated in place.
- **An older version with no migration path** — start-up **fails**, schema untouched.

From version 1.0 onwards the service never discards data: it stops rather than modify a schema it
cannot migrate. A failed upgrade therefore shows up as a pod that will not start, with the reason
in its log — not as an empty database.

Because a rollback across a schema version is refused, **downgrading is not a self-service fix**
once the version has moved. That is what the backup is for.

An upgrade that restarts the api lets requests already in flight finish first, for up to
`connectorManagement.shutdownDrainSeconds` (30 by default). The pod's grace period is derived
from it. Only connector and target deploys take long enough to notice, because they download
NARs from the resource provider. A deploy still running when the drain ends is cut off, cleaned
up, and can be retried.

## If NiFi loses its flows <!-- omit in toc -->

NiFi keeps its flows, NARs and queues on its PVC, so restarts and rolling updates leave
connectors running. If NiFi's volume is lost or replaced while the database is kept, the API still
records the connectors and targets as deployed and their schedules stop. On startup the API
redeploys any it deployed that NiFi no longer has (`connectorManagement.reconcileOnStartup`, on by
default), once it is ready; anything deployed but not running is only reported, in the API log.
The same check can be run at any time, for instance after restoring a backup:

```sh
curl -X POST "http://<host>/v1/admin/reconcile?dryRun=true"   # report only
curl -X POST "http://<host>/v1/admin/reconcile"               # redeploy what NiFi has lost
```

# Changing settings on a running deployment

Every value the chart gives NiFi is applied again whenever NiFi starts, not only on first install.
That includes the settings held in NiFi's flow itself: the root controller services for the
database, licensing, the proxy and flowfile storage.

- **Values set in the chart** — the licence server or OEM licence, the proxy, the database host,
  port and name — are part of NiFi's pod spec, so `helm upgrade` with a changed value restarts
  NiFi and applies it.
- **The database password** lives in a Secret, and the chart deliberately does not restart
  anything when a credential Secret changes. After rotating it, restart both workloads:

  ```sh
  kubectl rollout restart statefulset/<release>-<nifi.name> statefulset/<release>-<name>
  ```

- **An image upgrade** applies any change the new image makes to those services too.

Turning a service on or off, or switching between licence server and OEM licensing, needs no
further steps. When NiFi starts:

- Switching licence mode changes the licence service in place: to NiFi both modes are the same
  service, so everything using it carries on.
- Components that referenced a service that has gone are moved to a replacement offering the same
  interface, or the reference is cleared if there is none (turning the proxy off, say).
- A property that takes a service of the kind just added, and references nothing, is pointed at
  it. That covers connectors deployed before the service existed. A property already using a
  service that exists, such as one a connector's process group defines for itself, is kept.

The API then resolves those properties the same way each time it deploys a connector or target,
so redeploying one keeps the change.

The database, licence, proxy and flowfile-storage root services belong to the chart. An edit made
to them in the NiFi UI is reverted on the next restart, so change the chart's values instead.
Other components are left alone, including any root service you create yourself and every
connector's own process group. NiFi keeps the flow as it was before the last change alongside it,
at `data/conf/flow.json.gz.previous` on its volume.

The one setting that must never change is NiFi's sensitive-properties key — see
[Credentials and Secrets](#credentials-and-secrets).

# Uninstalling and cleaning up

`helm uninstall` does **not** remove this release's PersistentVolumeClaims: they are created by
the StatefulSet controller rather than by Helm, which defaults to retaining them. The generated
credential Secrets are retained too, so a reinstall onto the same volumes still has the passwords
that data was written with.

To discard a release completely — **this permanently destroys all connector state**:

```sh
kubectl delete pvc,secret -l app.kubernetes.io/instance=<release> -n <namespace>
kubectl get pv | grep <namespace>      # with reclaimPolicy Retain these stay Released
```

One selector covers the sub-charts' databases too. A claim supplied through `existingClaim` was
never owned by the release and is untouched.

# Production checklist

- [ ] **Enable authentication** — `connectorManagement.auth.enabled=true` with
      `connectorManagement.auth.jwksUri`, `issuer` and `audience` (the audience may be left unset
      only with the subscription check below on, for an issuer whose tokens carry none, such as
      OCP's OTDS). It is **off by default**, which
      leaves every `/v1/**` endpoint open to anything that can reach the Service or ingress.
- [ ] **Require a subscription to this application** — `auth.requireValidSubscription=true` with
      `auth.etsUrl` and `auth.validSubscriptionApplications`. Without it any valid OTDS token is
      accepted, whatever it is subscribed to.
- [ ] **Set `CONNECTORS_KEYS_PROVIDER_TYPE=database`** — the default `noop` stores connector
      credentials inline in the database rather than as tokenised references. Setting the type
      under `connectorManagement.env` is enough: the chart connects the key store to the same
      database as the state store, with the same credentials - the password from the same Secret -
      and it keeps its values in a `keys` table of its own. To use a separate database instead, set
      `CONNECTORS_KEYS_PROVIDER_DATABASE_CONNECTIONSTRING` and `..._USERNAME` there too, and
      `CONNECTORS_KEYS_PROVIDER_DATABASE_PASSWORD` through `connectorManagement.secretEnv` or
      `envFrom`; the chart then leaves the key store's connection to you.
- [ ] **Do not expose the bundled NiFi.** It runs HTTP-only with authentication disabled, so
      `nifi.ingress.enabled=true` publishes a fully editable NiFi UI.
- [ ] **Set `connectorManagement.ingress.host`, `connectorManagement.ingress.contextPath`, or
      both.** With neither, the rendered Ingress has no host and a path of `/(.*)`, so it claims
      the root of *every* hostname the ingress controller serves and can take traffic from
      anything else already there. Two releases in one namespace are the sharper version of the
      same problem: each gets its own Ingress object, so Helm and Kubernetes both accept them,
      but the rules are identical and the controller serves whichever it picks — silently, and
      `helm test` still passes because the tests go through the Service. Either value makes the
      rule specific; a host is the stronger choice.
- [ ] **Turn on `connectorManagement.nifi.tls.verify`** for an external NiFi. It is **off by
      default**, and until it is on an `https://` endpoint is encrypted but unauthenticated, so
      the connection is not protected against interception on an untrusted network.
- [ ] Check the image tags. `connectorManagement.image`, `nifi.image` and the
      DocumentSecurity image default to published, version-tagged artifacts in
      `cs-knowledgediscovery-docker-dev`; move them on when the project version does.
      `-f values-dev.yaml` switches all three to local docker builds.
- [ ] Supply your own credential Secrets if you deploy through GitOps.
- [ ] Set resource requests and limits to suit your workload, keeping
      `nifi.resources.limits.memory` comfortably above the maximum heap (`nifi.jvmHeapMaxPercentage`
      of that limit) plus `nifi.devShmSize`.
- [ ] Set `global.defaultStorageClass` if your cluster has no default.
- [ ] Take a backup before every upgrade, and run `helm test` after one.
- [ ] Plan for a single replica — see below.

# Known limitations

- **Single replica only.** Both StatefulSets are fixed at one replica. Coordination is
  in-process, there is no leader election, and the per-connector job limit is not race-proof
  across replicas. There is no HA configuration.
- **The bundled NiFi has no authentication and speaks plain HTTP**, including for the
  credentials the API sends it.
- **Certificate verification for an external NiFi is off by default** and must be turned on with
  `connectorManagement.nifi.tls.verify`. Mutual TLS is not supported at all — the API cannot
  present a client certificate. See
  [Verifying the NiFi certificate](#verifying-the-nifi-certificate).
- **The seccomp installer needs a root init container and a hostPath write** to place NiFi's
  Chrome sandbox profile on the node. That is rejected under PodSecurity `restricted` and by
  OpenShift's default SCC. Set `nifi.seccompProfile.type=Unconfined` and
  `nifi.seccompInstaller.enabled=false` there — the Chrome sandbox still works, but this pod
  loses seccomp filtering.
- **`podSecurityContext.fsGroup` is required on CSI storage** for the non-root container to write
  to provisioned volumes. It is ignored for hostPath volumes, so its effect is invisible on
  clusters using a hostPath provisioner.
- **The bitnami `postgresql-ha` images are pinned to the `bitnamilegacy` repositories**, which no
  longer receive updates. Review this against your vulnerability policy.
- **DocumentSecurity LDAP bind passwords** supplied through
  `documentsecurity.documentsecurity.repositories` are rendered into that chart's ConfigMap in
  plain text.
- **Two releases in one namespace share `app.kubernetes.io/name` on their PostgreSQL objects.**
  Names and selectors both stay release-scoped, so nothing cross-wires, but a selector written
  by hand on `app.kubernetes.io/name` alone matches both releases' pods. Include
  `app.kubernetes.io/instance` in any selector you write.

# IDOL licensing

## LicenseServer based <!-- omit in toc -->

```sh
helm install --set licenseServerHostname=my-licenseserver \
    --set-string licenseServerPort=20000 \
    my-deployment idol-connector-management-api
```

## OEM based <!-- omit in toc -->

```sh
# Create a secret containing oem licensekey.dat and versionkey.dat
kubectl create secret generic idol-oem-license \
    --from-file=licensekey.dat=/path/to/oem.licensekey.dat \
    --from-file=versionkey.dat=/path/to/versionkey.dat

helm install --set idolOemLicenseSecret=idol-oem-license \
    my-deployment idol-connector-management-api
```

# Bundling the DocumentSecurity API

The chart can optionally deploy the IDOL DocumentSecurity API as a sub-chart (disabled by
default). This is required if connectors will use the Groups operation, which pushes via the
`PutUserSecurity` NiFi processor to the DocumentSecurity REST API.

```yaml
documentsecurity:
  enabled: true
```

When enabled:

- DocumentSecurity is deployed on port 8082, overridden from its default 8080 to avoid clashing
  with the public API on 8080 and internal callbacks on 8081.
- Its objects are named from the release, like the rest of this chart's:
  `<release>-documentsecurity` for the API, and a `postgresql-ha` StatefulSet under
  `<release>-docsec-postgresql` so it does not collide with this chart's own
  `<release>-postgresql`. Two releases can therefore both bundle it in one namespace. To share
  one database instead, see [Complete stack](#2-complete-stack).
- `documentsecurity.documentsecurity.fullnameOverride` takes over that name — it is templated,
  so `'{{ .Release.Name }}-docsec'` works — and `nameOverride` replaces only the part after the
  release name. Both are followed by the `DOCSECURITY_API_URL` and the init container below, so
  a rename does not have to be applied in more than one place.
- The bundled NiFi gets `DOCSECURITY_API_URL` pointed at it automatically, which the
  `PutUserSecurity` processor resolves.
- A `wait-for-documentsecurity` init container is added to the API StatefulSet.

With an external DocumentSecurity API, leave `documentsecurity.enabled=false` and set
`nifi.env.DOCSECURITY_API_URL` to its URL instead.
