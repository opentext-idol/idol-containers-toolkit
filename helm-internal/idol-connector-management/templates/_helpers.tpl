{{/*
# BEGIN COPYRIGHT NOTICE
# Copyright 2023-2025 Open Text.
#
# The only warranties for products and services of Open Text and its affiliates and licensors
# ("Open Text") are as may be set forth in the express warranty statements accompanying such
# products and services. Nothing herein should be construed as constituting an additional warranty.
# Open Text shall not be liable for technical or editorial errors or omissions contained herein.
# The information contained herein is subject to change without notice.
#
# END COPYRIGHT NOTICE
*/}}

{{/*
Boilerplate for a `helm test` Pod. Called as:

    {{- include "idol-connector-management.test.pod" (dict "root" . "name" "health" "weight" 0 "image" $img "script" $script) }}

A bare Pod rather than a Job, because `helm test --logs` resolves a hook to a pod of the same
name: with a Job it looks for a pod called "<release>-<name>-test-<x>", finds only the Job's
generated "...-test-x-abcde", and fails with "unable to get pod logs ... not found" - so the
command exits non-zero even when every test passed. Since the README tells users to run
`helm test --logs`, that made a green run indistinguishable from a broken one.

restartPolicy Never so a failure is reported once rather than retried, and pods are kept after
the run - both passes and failures - so `helm test --logs` and `kubectl logs` can read them; the
previous run is removed when the next is created. The pod inherits the release's security
contexts and pull secrets: a test that cannot schedule under the same constraints as the
application tests nothing.

Note that `helm install`, including `--dry-run`, does NOT render test hooks. `helm test` is the
only thing that validates these manifests, so changes here need an actual test run.

`command` is overridden because the api image's ENTRYPOINT would otherwise generate a
configuration file and start Tomcat.
*/}}
{{- define "idol-connector-management.test.pod" -}}
{{- $root := .root -}}
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "idol-connector-management.fullname" $root }}-test-{{ .name }}
  {{- /* The `app` label must NOT be the api's own, which is what its Service selects on. A
         test pod carrying it becomes an endpoint of the very Service it is testing, so requests
         round-robin between the api and a pod with nothing listening - the tests then fail
         intermittently with HTTP 000 / "Could not connect", pointing at the api rather than at
         themselves. */}}
  labels: {{- include "idol-library.labels" (dict "root" $root "component" $root.Values.connectorManagement) | nindent 4 }}
    app: "{{ include "idol-connector-management.fullname" $root }}-test"
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-weight": {{ .weight | quote }}
    {{- /* before-hook-creation only: deleting on success races `helm test --logs`, which
           reads the pod after the hook completes, and leaves nothing to inspect. The previous
           run is removed when the next one is created. */}}
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  restartPolicy: Never
  automountServiceAccountToken: false
  enableServiceLinks: false
  {{- if $root.Values.podSecurityContext.enabled }}
  securityContext: {{- omit $root.Values.podSecurityContext "enabled" | toYaml | nindent 4 }}
  {{- end }}
  {{- with $root.Values.global.imagePullSecrets }}
  imagePullSecrets:
  {{- range . }}
  - name: {{ . }}
  {{- end }}
  {{- end }}
  containers:
  - name: test
    image: {{ .image }}
    imagePullPolicy: {{ include "idol-connector-management.imagePullPolicy" (dict "root" $root) }}
    {{- if $root.Values.containerSecurityContext.enabled }}
    securityContext: {{- omit $root.Values.containerSecurityContext "enabled" | toYaml | nindent 6 }}
      readOnlyRootFilesystem: true
    {{- end }}
    resources:
      requests:
        cpu: 20m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 128Mi
    command: ["bash", "-c"]
    args:
    - |
{{ .script | trim | indent 8 }}
{{- end -}}

{{/*
Shared shell prelude for the test scripts: `req <method-less url>` performs a GET and sets
$code and $body, without writing to the filesystem so the tests still work with
readOnlyRootFilesystem. `expect <code> <url> <what>` asserts a status and exits non-zero
with a readable message.
*/}}
{{- define "idol-connector-management.test.prelude" -}}
set -eu
FAILED=0

# GET a URL, setting $code and $body. Nothing is written to the filesystem, so the tests still
# work under readOnlyRootFilesystem.
#
# A connection-level failure yields code 000 and is retried: `helm test` can run moments after
# an upgrade, before kube-proxy has programmed every Service port, and a test that fails on
# that races the cluster rather than checking the application. A *wrong HTTP status* is a real
# result and is never retried, so the assertions stay strict.
#
# Three attempts at 10s with 2s between them by default: enough to ride out endpoint
# programming, but a genuinely unreachable URL still fails in about 35s rather than minutes,
# which matters because every assertion in a test pays that cost before the test can report.
#
# A suite whose endpoint is legitimately slow raises REQ_TIMEOUT before its first assertion. It
# has to: a curl timeout and an unreachable port are both reported as 000 here, so too small a
# budget reports a working endpoint as unreachable - which is exactly what the type endpoints
# did on a cold resource cache.
REQ_TIMEOUT="${REQ_TIMEOUT:-10}"
REQ_ATTEMPTS="${REQ_ATTEMPTS:-3}"

req() {
  url="$1"
  attempt=1
  while true; do
    if resp=$(curl -sS -m "$REQ_TIMEOUT" -w '\n%{http_code}' "$url" 2>&1); then
      code=$(printf '%s' "$resp" | tail -n1)
      body=$(printf '%s' "$resp" | sed '$d')
    else
      code="000"
      body="$resp"
    fi
    if [ "$code" != "000" ]; then
      return 0
    fi
    if [ "$attempt" -ge "$REQ_ATTEMPTS" ]; then
      return 0
    fi
    echo "  ....  $url not answering yet (attempt $attempt), retrying"
    attempt=$((attempt + 1))
    sleep 2
  done
}

# Assert an exact status. 000 (could not connect) never satisfies an assertion.
expect() {
  want="$1"; url="$2"; what="$3"
  req "$url"
  if [ "$code" = "$want" ]; then
    echo "  PASS  $what (HTTP $code)"
  else
    echo "  FAIL  $what: expected HTTP $want, got $code"
    echo "        $url"
    printf '        %s\n' "$body" | head -5
    FAILED=1
  fi
}

# Assert the request reached the application and was not rejected with $unwanted. Requires a
# real HTTP response: 000 is a failure, not a pass - otherwise an unreachable endpoint would
# satisfy a "not forbidden" style check.
expect_not() {
  unwanted="$1"; url="$2"; what="$3"
  req "$url"
  if [ "$code" = "000" ]; then
    echo "  FAIL  $what: no HTTP response at all"
    echo "        $url"
    printf '        %s\n' "$body" | head -3
    FAILED=1
  elif [ "$code" = "$unwanted" ]; then
    echo "  FAIL  $what: got the rejected status HTTP $code"
    echo "        $url"
    FAILED=1
  else
    echo "  PASS  $what (HTTP $code)"
  fi
}
{{- end -}}

{{/*
Release-scoped object names.

Every object this chart creates is named <release>-<component>, so two releases can
coexist in one namespace. Previously the names were fixed (idol-connector-management,
idol-nifi), which meant a second release in the same namespace collided with the first
- while the postgresql sub-chart, which does prefix with the release, did not.

`.Values.name` / `.Values.nifi.name` remain the component names (the suffix);
fullnameOverride takes over the whole name when a specific one is required.

Truncated to 60 rather than the usual 63: these name StatefulSets, whose pods are
<name>-<ordinal>, and every DNS label is capped at 63 characters. 60 leaves room for
the ordinal suffix.

Following the standard Helm idiom, a release name that already contains the component
name is not prefixed again, so `helm install idol-connector-management .` does not
produce idol-connector-management-idol-connector-management.
*/}}
{{- define "idol-connector-management.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 60 | trimSuffix "-" -}}
{{- else if contains .Values.name .Release.Name -}}
{{- .Release.Name | trunc 60 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Values.name | trunc 60 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "idol-connector-management.nifi.fullname" -}}
{{- if .Values.nifi.fullnameOverride -}}
{{- .Values.nifi.fullnameOverride | trunc 60 | trimSuffix "-" -}}
{{- else if contains .Values.nifi.name .Release.Name -}}
{{- .Release.Name | trunc 60 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Values.nifi.name | trunc 60 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Names the bundled idol-documentsecurity sub-chart gives its own objects.

Needed because this chart references them: the api waits for the DocumentSecurity Service
before starting, and NiFi's PutUserSecurity processor is handed its URL. A sub-chart computes
its names in its own context, which this chart cannot read, so the rule has to be mirrored -
these two definitions must stay in step with `idol-documentsecurity.fullname` and
`idol-documentsecurity.postgresql.fullname` in that chart.

Mirroring is verifiable rather than a matter of trust: the Service the sub-chart renders and
the DOCSECURITY_API_URL this chart renders are both in the output of a single
`helm template`, so a drift shows up as two different strings.
*/}}
{{- define "idol-connector-management.documentsecurity.fullname" -}}
{{- $ds := .Values.documentsecurity.documentsecurity | default dict -}}
{{- if $ds.fullnameOverride -}}
{{- tpl $ds.fullnameOverride . | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := $ds.nameOverride | default "documentsecurity" -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "idol-connector-management.documentsecurity.postgresql.fullname" -}}
{{- $pg := (.Values.documentsecurity.postgresql | default dict) -}}
{{- if $pg.fullnameOverride -}}
{{- $pg.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := $pg.nameOverride | default "docsec-postgresql" -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Effective imagePullPolicy for a container: the component's own setting if it has
one, else global.imagePullPolicy, else IfNotPresent. Matches the precedence the
documentsecurity sub-chart uses, so a single global.imagePullPolicy applies
consistently across every container this chart and its sub-charts create.

    {{ include "idol-connector-management.imagePullPolicy" (dict "root" . "component" .Values.nifi.imagePullPolicy) }}

Omit "component" for containers with no per-component setting (the busybox init
containers), so they fall straight through to the global.
*/}}
{{- define "idol-connector-management.imagePullPolicy" -}}
{{- or (.component | default "") .root.Values.global.imagePullPolicy "IfNotPresent" -}}
{{- end -}}

{{/*
ServiceAccount for a pod: the component's own serviceAccountName if it has one,
else the chart-wide serviceAccountName, else empty (so the field is omitted and
the namespace's `default` account applies).

Deliberately NOT a global. The reason to set a ServiceAccount at all is almost
always to bind a cloud identity (GKE Workload Identity, EKS IRSA, Azure WI), and
that is exactly when the pods should NOT share one: a single account grants every
pod the union of the permissions any of them needs. The api may need Cloud Run
and the resources bucket, while NiFi - which runs connector code, headless Chrome
and ExecuteDocumentLua/Python - should be scoped to its own flowfile bucket.
*/}}
{{- define "idol-connector-management.serviceAccountName" -}}
{{- or (.component | default "") .root.Values.serviceAccountName -}}
{{- end -}}

{{/*
Emit a storageClassName line for a PVC: the component's own storageClass if it
has one, else global.defaultStorageClass, else nothing at all - which leaves the
cluster's own default StorageClass to apply. Matches the precedence bitnami's
common.storage.class uses, so one global.defaultStorageClass drives every PVC
this chart and its sub-charts create.

    {{- include "idol-connector-management.storageClass" (dict "root" . "component" .Values.nifi.dataVolume.storageClass) | nindent 6 }}

Following bitnami, a value of "-" means storageClassName: "" - i.e. explicitly
no class, disabling dynamic provisioning.
*/}}
{{- define "idol-connector-management.storageClass" -}}
{{- $sc := or (.component | default "") .root.Values.global.defaultStorageClass -}}
{{- if $sc -}}
{{- if eq $sc "-" -}}
storageClassName: ""
{{- else -}}
storageClassName: {{ $sc | quote }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Names of the Secrets holding this release's credentials. Each may be replaced by a
user-managed Secret, which is the escape hatch for GitOps: see the note on `lookup`
below for why chart-side generation and Argo CD / Flux do not mix.
*/}}
{{/*
Derived from the release name alone, NOT from the chart fullname. The postgresql-ha
sub-chart is pointed at this Secret through its own existingSecret values, and it `tpl`s
those in its OWN context - where `.Values` is the sub-chart's values, so `.Values.name`
and any fullnameOverride are invisible and would silently expand to nothing. `.Release`
is shared, so a release-derived name resolves identically on both sides.
*/}}
{{/*
The user-supplied credential Secret, if there is one, for whichever database is in use.

Each mode has its own value because the two Secrets are not interchangeable: one for the
bundled database has to carry bitnami's key names (password, repmgr-password,
admin-password) and be wired into the sub-chart's own existingSecret values as well, while
one for an external instance needs only a password and may name its keys freely
(externalPostgresql.existingSecretPasswordKey / -UsernameKey). Only one is ever in force, so
reading the mode here keeps each block self-contained.
*/}}
{{- define "idol-connector-management.postgresql.existingSecret" -}}
{{- if .Values.postgresql.enabled -}}
{{- .Values.postgresql.existingSecret -}}
{{- else -}}
{{- (.Values.externalPostgresql | default dict).existingSecret -}}
{{- end -}}
{{- end -}}

{{- define "idol-connector-management.postgresql.secretName" -}}
{{- include "idol-connector-management.postgresql.existingSecret" . | default (printf "%s-postgresql-credentials" .Release.Name) -}}
{{- end -}}

{{- define "idol-connector-management.nifi.sensitivePropsSecretName" -}}
{{- .Values.nifi.existingSensitivePropsSecret | default (printf "%s-sensitive-props" (include "idol-connector-management.nifi.fullname" .)) -}}
{{- end -}}

{{- define "idol-connector-management.secretEnvName" -}}
{{- printf "%s-env" (include "idol-connector-management.fullname" .) -}}
{{- end -}}

{{/*
Resolve one Secret key to a base64 value: an explicitly configured value if there is
one, else the value already in the cluster (so it survives `helm upgrade`), else a
freshly generated one. Returns base64 because it is consumed directly in Secret `data`.

    {{ include "idol-connector-management.secretValue" (dict "root" . "name" $n "key" "password" "explicit" $v "generate" true) }}

Generation MUST happen in one template only. If a consumer also called this while the
Secret did not yet exist, it would generate a *different* value in the same render -
hence every consumer references the Secret with secretKeyRef and never the value.

`lookup` returns nothing when there is no cluster connection, which is the case for
`helm template` and client-side `--dry-run`. Rendered output therefore shows a new
random value each time, and `helm template | kubectl apply` would rotate credentials on
every apply - use `helm install/upgrade`, or supply your own Secret.
*/}}
{{- define "idol-connector-management.secretValue" -}}
{{- if .explicit -}}
{{- .explicit | toString | b64enc -}}
{{- else if .generate -}}
{{- $old := (lookup "v1" "Secret" .root.Release.Namespace .name).data | default dict -}}
{{- index $old .key | default (randAlphaNum 32 | b64enc) -}}
{{- else -}}
{{- "" | b64enc -}}
{{- end -}}
{{- end -}}

{{/*
The sensitive environment the api takes from a Secret rather than the ConfigMap:
connectorManagement.secretEnv verbatim, plus the NiFi API password. Returned as YAML of
already-base64 values so the Secret template and the StatefulSet agree on whether there
is anything to mount.
*/}}
{{- define "idol-connector-management.secretEnv.data" -}}
{{- $data := dict -}}
{{- range $k, $v := (.Values.connectorManagement.secretEnv | default dict) -}}
{{- $_ := set $data $k ($v | toString | b64enc) -}}
{{- end -}}
{{- /* Skipped when the NiFi credentials come from a Secret the user manages - it is then
       referenced directly, and copying the value here would be both redundant and a
       second place to keep in step. */}}
{{- if and .Values.connectorManagement.nifi.password (not .Values.connectorManagement.nifi.existingSecret) -}}
{{- $_ := set $data "NIFI_PASSWORD" (.Values.connectorManagement.nifi.password | toString | b64enc) -}}
{{- end -}}
{{- /* Same reasoning for the trust store password. Only meaningful when verification is on
       and the trust material is a store rather than a PEM file. */}}
{{- $tls := .Values.connectorManagement.nifi.tls -}}
{{- if and $tls.verify $tls.trustStorePassword (not $tls.existingTrustStorePasswordSecret) -}}
{{- $_ := set $data "NIFI_TLS_TRUSTSTORE_PASSWORD" ($tls.trustStorePassword | toString | b64enc) -}}
{{- end -}}
{{- toYaml $data -}}
{{- end -}}

{{/*
Which Secret key holds the database password, and optionally the username.

Both only apply to an external database. The bundled postgresql-ha sub-chart hardcodes
`password` in its own secretKeyRefs and reads the username from its values, so a custom
key there would either mismatch bitnami or be silently ignored. Rather than quietly
dropping the setting, reject the combination.
*/}}
{{- define "idol-connector-management.postgresql.passwordKey" -}}
{{- $key := (.Values.externalPostgresql | default dict).existingSecretPasswordKey | default "password" -}}
{{- if and .Values.postgresql.enabled (ne $key "password") -}}
{{- fail (printf "\n\nexternalPostgresql.existingSecretPasswordKey is %q, but the bundled database requires \"password\".\n\nThe postgresql-ha sub-chart references that key name directly, so a different one would\nleave PostgreSQL and the api reading different keys. Either use the default, or set\npostgresql.enabled=false and point at your own external instance.\n" $key) -}}
{{- end -}}
{{- $key -}}
{{- end -}}

{{- define "idol-connector-management.postgresql.usernameKey" -}}
{{- $key := (.Values.externalPostgresql | default dict).existingSecretUsernameKey | default "" -}}
{{- if and .Values.postgresql.enabled $key -}}
{{- fail (printf "\n\nexternalPostgresql.existingSecretUsernameKey is set (%q) but postgresql.enabled is true.\n\nThe bundled sub-chart takes its username from postgresql.postgresql.username, not from a\nSecret, so this would be a second source of truth that bitnami ignores. Set the username\nin values for the bundled database, or use it with an external instance.\n" $key) -}}
{{- end -}}
{{- $key -}}
{{- end -}}

{{/*
Where the NiFi trust material is mounted, and the full path to the file within it.

Emits nothing when certificate verification is off, or is on with no trust material of its
own - in which case the JVM's default trust store is used and there is nothing to mount.
Also rejects the combinations that cannot be honoured, rather than silently picking one.
*/}}
{{- define "idol-connector-management.nifi.tls.mountPath" -}}
/etc/nifi-tls
{{- end -}}

{{- define "idol-connector-management.nifi.tls.caFile" -}}
{{- $tls := .Values.connectorManagement.nifi.tls -}}
{{- if $tls.verify -}}
{{- if and $tls.existingCaSecret $tls.existingCaConfigMap -}}
{{- fail "\n\nBoth connectorManagement.nifi.tls.existingCaSecret and .existingCaConfigMap are set.\n\nThe certificate can only be mounted from one of them - set whichever holds it and clear\nthe other.\n" -}}
{{- end -}}
{{- if or $tls.existingCaSecret $tls.existingCaConfigMap -}}
{{- if not $tls.caKey -}}
{{- fail "\n\nconnectorManagement.nifi.tls.caKey is empty.\n\nIt names the key within the Secret or ConfigMap holding the certificate, and becomes the\nfilename the api reads.\n" -}}
{{- end -}}
{{- printf "%s/%s" (include "idol-connector-management.nifi.tls.mountPath" .) $tls.caKey -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Whether the mounted trust material is a trust store rather than a PEM file, taken from the
extension of caKey. Decides which env var the path is passed in, since the two are read
differently.
*/}}
{{- define "idol-connector-management.nifi.tls.isTrustStore" -}}
{{- $key := .Values.connectorManagement.nifi.tls.caKey | default "" | lower -}}
{{- if or (hasSuffix ".p12" $key) (hasSuffix ".pfx" $key) (hasSuffix ".jks" $key) }}true{{ end -}}
{{- end -}}

{{/*
Whether a PostgreSQL instance is reachable at all - either the bundled subchart
or an external one described by externalPostgresql.host. Used to decide whether
to emit the wait-for-postgres init containers.
*/}}
{{- define "idol-connector-management.postgresql.configured" -}}
{{- if or .Values.postgresql.enabled (.Values.externalPostgresql | default dict).host }}true{{ end -}}
{{- end -}}

{{/*
Reject an additionalVolumeMounts entry that lands on a path this chart already mounts.

Worth checking explicitly because the failure is close to undiagnosable. Kubernetes requires
mountPath to be unique within a container, but only enforces it when a *Pod* is created - a
StatefulSet carrying the same pod template is accepted. So `helm install` succeeds, the PVC is
provisioned, no pod is ever created, `--wait` hangs to its timeout, and the only evidence is an
event on the StatefulSet:

    Warning FailedCreate ... spec.containers[0].volumeMounts[1].mountPath:
      Invalid value: "/opt/nifi-connector-management/resources": must be unique

Neither `helm install --dry-run` nor `--dry-run=server` catches it, so lint/template/dry-run
all pass on a release that can never run a pod.
*/}}
{{- define "idol-connector-management.validateResourcesSource" -}}
{{- $owned := dict -}}
{{- if .Values.connectorManagement.resourcesVolume.enabled -}}
{{- $_ := set $owned "/opt/nifi-connector-management/resources" "connectorManagement.resourcesVolume" -}}
{{- end -}}
{{- if .Values.connectorManagement.cacheVolume.enabled -}}
{{- with index (.Values.connectorManagement.env | default dict) "CONNECTORS_STORAGE_PROVIDER_CACHE_DIR" -}}
{{- $_ := set $owned . "connectorManagement.cacheVolume" -}}
{{- end -}}
{{- end -}}
{{- if include "idol-connector-management.nifi.tls.caFile" . -}}
{{- $_ := set $owned (include "idol-connector-management.nifi.tls.mountPath" .) "connectorManagement.nifi.tls" -}}
{{- end -}}
{{- range .Values.additionalVolumeMounts -}}
{{- $clash := index $owned (.mountPath | default "") -}}
{{- if $clash -}}
{{- fail (printf "\n\nTwo volumes mounted at the same path.\n\nAn additionalVolumeMounts entry mounts %q, which this chart already mounts there for %s. Kubernetes rejects that when it creates the pod rather than when it accepts the StatefulSet, so the release would install without complaint and then run no pods at all.\n\nMount it somewhere else. To supply the connector resource set from a directory on the node, mount it at a path of its own and point the provider at it with connectorManagement.env.CONNECTORS_STORAGE_PROVIDER_FILESYSTEM_DIRECTORY - see \"Connector resources\" in the chart README.\n" .mountPath $clash) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The NiFi endpoint the api should use, and a guard for there being none.

Rendering fails when neither the bundled NiFi nor an external endpoint is configured. The
api's readiness probe pings NiFi unconditionally, and with nothing configured the container
falls back to https://localhost:8443 (see docker/api/entrypoint.sh), where nothing is
listening - so the release would install cleanly and then never become ready, with the
reason being a fallback nobody chose. Same reasoning as the database guard below.
*/}}
{{- define "idol-connector-management.nifi.endpoint" -}}
{{- if .Values.nifi.enabled -}}
{{- $n := include "idol-connector-management.nifi.fullname" . -}}
{{- printf "http://%s-0.%s-headless:8080/nifi" $n $n -}}
{{- else if .Values.connectorManagement.nifi.endpoint -}}
{{- .Values.connectorManagement.nifi.endpoint -}}
{{- else -}}
{{- fail "\n\nNo NiFi configured.\n\nnifi.enabled is false and connectorManagement.nifi.endpoint is not set, so the api has no NiFi to deploy flows to. Either:\n  - set nifi.enabled=true to deploy the bundled NiFi, or\n  - set connectorManagement.nifi.endpoint to an existing NiFi (with connectorManagement.nifi.username/password, or existingSecret, if it requires authentication).\n\nThis is enforced because NiFi is a required readiness check and the container defaults to\nhttps://localhost:8443 when no endpoint is supplied: the release would install without\ncomplaint and then never become ready.\n" -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the PostgreSQL connection details shared by the connector-management API
and the bundled NiFi. Returns a YAML mapping, so callers parse it with fromYaml:

    {{- $pg := include "idol-connector-management.postgresql" . | fromYaml }}

With postgresql.enabled=true the bundled postgresql-ha subchart is used and the
connection resolves to its pgpool Service, with the credentials the subchart was
given. With postgresql.enabled=false the chart targets the existing instance
described by externalPostgresql; its database/username/password fall back to the
subchart values, so a stock-configured instance needs only its host to be set.

Rendering fails when neither is configured. Without the guard the API would
start against the embedded HSQLDB fallback baked into the container entrypoint,
pass its readiness probe, and lose all connector state on the next restart.
*/}}
{{- define "idol-connector-management.postgresql" -}}
{{- $pg := .Values.postgresql -}}
{{- $sub := $pg.postgresql | default dict -}}
{{- $ext := .Values.externalPostgresql | default dict -}}
{{- $host := "" -}}
{{- $port := "5432" -}}
{{- if $pg.enabled -}}
{{- $host = printf "%s-postgresql-pgpool" .Release.Name -}}
{{- else -}}
{{- if not $ext.host -}}
{{- fail (printf "\n\nNo database configured.\n\npostgresql.enabled is false but externalPostgresql.host is not set, so this release has nowhere to store connector state. Either:\n  - set postgresql.enabled=true to deploy the bundled PostgreSQL, or\n  - set externalPostgresql.host (and externalPostgresql.port/database/username/password as needed) to point at an existing PostgreSQL instance.\n\nThis is enforced because the container falls back to an ephemeral embedded HSQLDB when no connection string is supplied: the API would come up healthy and then lose every connector, target and job on the next pod restart.\n") -}}
{{- end -}}
{{- $host = $ext.host -}}
{{- $port = $ext.port | default 5432 | toString -}}
{{- end -}}
host: {{ $host | quote }}
port: {{ $port | quote }}
database: {{ $ext.database | default $sub.database | quote }}
username: {{ $ext.username | default $sub.username | quote }}
password: {{ $ext.password | default $sub.password | quote }}
{{- end -}}

{{/*
JDBC URL for the resolved PostgreSQL connection, with postgresql.jdbcParameters
appended (the leading '?' is added if omitted) for options an external instance
may require, e.g. sslmode=require.
*/}}
{{- define "idol-connector-management.postgresql.jdbcUrl" -}}
{{- $pg := include "idol-connector-management.postgresql" . | fromYaml -}}
{{- $params := .Values.postgresql.jdbcParameters | default "" -}}
{{- if and $params (not (hasPrefix "?" $params)) -}}
{{- $params = printf "?%s" $params -}}
{{- end -}}
{{- printf "jdbc:postgresql://%s:%s/%s%s" $pg.host $pg.port $pg.database $params -}}
{{- end -}}

{{/*
Whether the chart connects a `database` key store to the database it gives the state store.

True when CONNECTORS_KEYS_PROVIDER_TYPE is "database" in connectorManagement.env, no key store
connection string is given there, and the chart owns the state store's connection (no
CONNECTORS_STATE_PROVIDER_DATABASE_CONNECTIONSTRING there either). The key store then uses the
same JDBC URL and credentials - its username alongside the state store's, its password from the
same Secret - and creates its own `keys` table beside the state tables. A key store connection
string given in env takes over, with its credentials, exactly as the state store's does.
*/}}
{{- define "idol-connector-management.keyStore.usesStateDatabase" -}}
{{- $env := .Values.connectorManagement.env | default dict -}}
{{- if and (eq (toString (index $env "CONNECTORS_KEYS_PROVIDER_TYPE" | default "")) "database")
           (not (hasKey $env "CONNECTORS_KEYS_PROVIDER_DATABASE_CONNECTIONSTRING"))
           (not (hasKey $env "CONNECTORS_STATE_PROVIDER_DATABASE_CONNECTIONSTRING")) -}}
true
{{- end -}}
{{- end -}}

{{/*
The service account the bundled Prometheus server runs as, named exactly as the prometheus
sub-chart names it (its prometheus.serviceAccountName.server and prometheus.server.fullname
helpers), so prometheus-rbac.yaml can bind to it. A sub-chart's helpers cannot be called from the
parent with the sub-chart's values, hence the copy - keep it in step if the sub-chart is upgraded.
*/}}
{{- define "idol-connector-management.prometheus.serverServiceAccount" -}}
{{- $p := .Values.prometheus -}}
{{- $sa := ($p.serviceAccounts | default dict).server | default dict -}}
{{- $server := $p.server | default dict -}}
{{- if and (hasKey $sa "create") (not $sa.create) -}}
{{- $sa.name | default "default" -}}
{{- else if $sa.name -}}
{{- $sa.name -}}
{{- else if $server.fullnameOverride -}}
{{- $server.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := $p.nameOverride | default "prometheus" -}}
{{- $serverName := $server.name | default "server" -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name $serverName | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name $serverName | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}
