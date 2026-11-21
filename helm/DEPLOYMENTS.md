# Deployments

Every Helm release in the cluster is declared in [`helmfile.yaml`](./helmfile.yaml),
with custom values kept in [`values/`](./values). Resources that are not Helm
charts (such as the MetalLB address pool) live in [`../kustomize`](../kustomize).

k3s is started with `--disable servicelb`, `--disable traefik`, and
`--disable local-storage` (see `nixos/system/homelab.nix`), so the built-in load
balancer, ingress controller, and storage class are replaced by the releases
below.

## Summary

| Release                  | Namespace         | Chart                            | Version | Values                                                                  |
| ------------------------ | ----------------- | -------------------------------- | ------- | ----------------------------------------------------------------------- |
| `longhorn`               | `longhorn-system` | `longhorn/longhorn`              | 1.9.1   | chart defaults                                                          |
| `metallb`                | `metallb-system`  | `metallb/metallb`                | 0.15.2  | chart defaults (pool in `kustomize/metallb`)                            |
| `pihole`                 | `pihole-system`   | `mojo2600/pihole`                | 2.34.0  | [`pihole.values.yaml`](./values/pihole.values.yaml)                     |
| `ingress-nginx-internal` | `nginx-system`    | `ingress-nginx/ingress-nginx`    | 4.11.2  | [`nginx-internal.values.yaml`](./values/nginx-internal.values.yaml)     |
| `externaldns-pihole`     | `pihole-system`   | `kubernetes-sigs/external-dns`   | 1.18.0  | [`externaldns.values.yaml`](./values/externaldns.values.yaml)           |
| `postgres` (disabled)    | `postgresql-system` | `bitnami/postgresql`           | 16.4.5  | [`postgresql.values.yaml`](./values/postgresql.values.yaml)             |

### IP addresses

| Address         | Used by                                      |
| --------------- | -------------------------------------------- |
| 192.168.1.64    | `homelab-0` node                             |
| 192.168.1.65    | `homelab-1` node                             |
| 192.168.1.192/26 | MetalLB pool (192.168.1.192 – 192.168.1.255) |
| 192.168.1.250   | Pi-hole web UI (`pihole.lab`)                |
| 192.168.1.251   | Pi-hole DNS (port 53)                        |

## Longhorn

Distributed block storage for the cluster. Longhorn replicates volumes across
nodes and provides the `longhorn` StorageClass, which replaces the k3s
`local-path` provisioner. Any PersistentVolumeClaim that needs to survive a node
failure (such as Pi-hole's configuration) should use `storageClassName: longhorn`.

- Chart: <https://charts.longhorn.io>
- Configuration: chart defaults; no values file.

## MetalLB

Bare-metal load balancer that assigns real LAN IPs to `type: LoadBalancer`
Services, replacing the k3s `servicelb`. The chart installs only the controller
and speakers; the address pool comes from
[`kustomize/metallb/pool.yaml`](../kustomize/metallb/pool.yaml):

- `IPAddressPool` `pool`: `192.168.1.192/26`.
- `L2Advertisement` `homelab`: announces addresses from `pool` over ARP (layer 2
  mode), so no router configuration is needed.

Keep the router's DHCP range out of `192.168.1.192/26` to avoid address
conflicts. Apply the pool after the chart is installed, since it depends on the
MetalLB CRDs:

```
kubectl apply -k kustomize
```

## Pi-hole

Network-wide DNS server and ad blocker for the home network.

Key settings in [`pihole.values.yaml`](./values/pihole.values.yaml):

- **Upstream DNS:** `DNS1` and `DNS2` (`1.1.1.1`) are the resolvers Pi-hole
  forwards to.
- **Local records:** `dnsmasq.customDnsEntries` resolves `homelab-0` and
  `homelab-1` to their node IPs. Commented-out entries for the PostgreSQL
  services are kept for when that release is re-enabled.
- **Storage:** configuration is stored on a Longhorn-backed PVC.
- **Services:** the web UI and DNS are separate `LoadBalancer` Services pinned
  to `192.168.1.250` and `192.168.1.251`. Both carry the
  `metallb.universe.tf/allow-shared-ip: pihole-svc` annotation so MetalLB lets
  them share IPs if needed.
- **Hostname:** the web Service is annotated with
  `external-dns.alpha.kubernetes.io/hostname: pihole.lab`, and an
  `nginx-internal` Ingress serves `pihole.lab`.
- **Replicas:** 1.

To use it, point the router's (or each client's) DNS server at `192.168.1.251`.

## ingress-nginx (internal)

NGINX Ingress controller for services reachable on the local network, replacing
the k3s Traefik ingress.

Key settings in [`nginx-internal.values.yaml`](./values/nginx-internal.values.yaml):

- Creates the IngressClass `nginx-internal` and marks it as the cluster default,
  so Ingresses without an `ingressClassName` are served by this controller.
- The controller Service is `type: LoadBalancer` (chart default), so MetalLB
  gives it an address from the pool.

The `-internal` suffix leaves room for a separate public-facing controller
later.

## ExternalDNS (Pi-hole)

Creates DNS records in Pi-hole automatically from Kubernetes Services, so new
services get a `.lab` hostname without editing Pi-hole by hand.

Key settings in [`externaldns.values.yaml`](./values/externaldns.values.yaml):

- **Provider:** `pihole`, using the Pi-hole v6 API at `http://192.168.1.250`
  (the web Service's MetalLB IP).
- **Sources:** `service` only. Annotate a Service with
  `external-dns.alpha.kubernetes.io/hostname: <name>.lab` to publish it.
  Ingress sources are not enabled.
- **Policy:** `upsert-only`, so records are created and updated but never
  deleted. Remove stale records in the Pi-hole UI.
- **Registry:** `noop`. Pi-hole cannot store TXT ownership records, so
  `txtOwnerId: homelab` has no effect.
- **Auth:** reads the Pi-hole admin password from the `password` key of the
  Secret `pihole-password` in `pihole-system`. This Secret is not managed by
  this repo and must exist before the release starts:

```
kubectl -n pihole-system create secret generic pihole-password --from-literal=password='<pihole admin password>'
```

## PostgreSQL (disabled)

A replicated PostgreSQL instance for local development. The release is commented
out in `helmfile.yaml`, and the `bitnami` repository is not listed under
`repositories`, so add it back before re-enabling the release.

Key settings in [`postgresql.values.yaml`](./values/postgresql.values.yaml):

- `architecture: replication`, with a primary (`lab-primary`) and read replicas
  (`lab-read`).
- Both are exposed as `LoadBalancer` Services on port 5432.
- The primary uses a 10 Gi `ReadWriteOnce` volume; replicas use persistent
  storage with chart-default size.

## Applying changes

From the `helm` directory:

```
helmfile diff    # preview changes
helmfile apply   # install or upgrade releases
```
