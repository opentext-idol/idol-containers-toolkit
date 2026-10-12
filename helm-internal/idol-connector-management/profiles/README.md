# NiFi seccomp profile — `nifi-chrome-sandbox.json`

## Why this exists
The Web connector drives headless Chrome. Chrome's preferred sandbox creates an
**unprivileged user namespace**. The Kubernetes `RuntimeDefault` seccomp profile gates the
namespace/mount syscalls (`clone`/`clone3`/`unshare`/`setns`/`mount`/`umount2`/`pivot_root`/
`chroot`) behind `CAP_SYS_ADMIN`; because the NiFi pod runs non-root with **all capabilities
dropped**, those syscalls return `EPERM` and Chrome aborts at launch:

```
Failed to move to new namespace: ... Operation not permitted
FATAL ... zygote_host ... Check failed: Operation not permitted
```
(surfaced by the connector as `DevToolsActivePort file not found after timeout`).

## What it does
`defaultAction: SCMP_ACT_ALLOW` with a **targeted deny-list** of dangerous, host-affecting
syscalls. Net effect:
- **Permits** the namespace/mount syscalls Chrome's sandbox needs (they are simply not in the
  deny-list) — so **Chrome's sandbox stays ON** under non-root + dropped caps + no_new_privs.
- **Blocks** kernel-module management, `kexec`, `reboot`, swap, raw I/O ports (`ioperm`/`iopl`),
  time-setting, `bpf`, `perf_event_open`, `open_by_handle_at`, `quotactl`, `acct`, and other
  legacy/privileged calls. None are used by the NiFi JVM or by Chrome's sandbox.

This is deliberately **allow-by-default + deny-dangerous**, not a full `RuntimeDefault`-style
deny-by-default allow-list. Rationale: a hand-authored deny-by-default profile must enumerate
~350 syscalls, and a single omission crashes the JVM in hard-to-debug ways. Allow-by-default is
safe for the workload and still removes the classic container-escape / host-damage primitives.
It is more permissive than `RuntimeDefault` and less permissive than `Unconfined`.

Known restriction: `perf_event_open` is denied, so `async-profiler`-style profiling of the NiFi
JVM won't work in-pod (JFR is unaffected). Remove it from the deny-list if you need that.

## Getting the profile onto the node
Kubernetes `localhostProfile` files are read by the kubelet from the **node** filesystem, under
the kubelet seccomp root (default `/var/lib/kubelet/seccomp/`) — never from the container image.
The chart references `localhostProfile: profiles/nifi-chrome-sandbox.json`, so the file must
exist at `/var/lib/kubelet/seccomp/profiles/nifi-chrome-sandbox.json` on whatever node runs the
NiFi pod, before the container is created.

**The chart handles this automatically** via the `install-seccomp-profile` **init container** in
the NiFi StatefulSet (controlled by `nifi.seccompInstaller`, enabled by default). It:
- carries the profile in a ConfigMap (`<nifi.name>-seccomp`, generated from this file),
- overrides its own seccomp to `RuntimeDefault` so it can start before the profile exists,
- runs as root and copies the profile into the kubelet seccomp dir via a `hostPath`, then exits.

Because it is a one-shot init that is synchronous with the pod, the profile is guaranteed present
before the main container starts — there is no `CreateContainerError` race. If the NiFi pod is
rescheduled to another node, its init reinstalls the profile there. Requirement: the namespace
must permit `hostPath` volumes and a root pod (PodSecurity baseline/privileged, not `restricted`).

Alternatives to the init container (set `nifi.seccompInstaller.enabled: false`): bake the file
into the node image / node-bootstrap, or use the Security Profiles Operator.

## Fallback
If you can't run the init container (e.g. the namespace forbids hostPath/root), set
`nifi.seccompProfile.type: Unconfined` — Chrome's sandbox still works (userns syscalls
unfiltered), at the cost of dropping seccomp filtering for the NiFi pod only.
