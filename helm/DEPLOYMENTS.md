# Deployments

This directory hosts the helm releases for my homelab cluster.

All deployments are managed by `heml` via `helmfile` specs, which provides a
[declarative spec](https://github.com/helmfile/helmfile) for deploying helm
charts.

## Deployment List

The following deployments are provided in this directory. Links to the original
charts can be found in the `helmfile.yaml`.

| Deployment Name | Version | Description                                                                                                                                                                                                                                              |
| --------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `longhorn`      | 1.9.1   | Provides shared/distributed storage for the homelab cluster, using the local disk of the nodes. This allows persistent volumes and other stateful storage to leverage the combined cluster hardware specs rather than be limited to one node's hardware. |
| `metallb`       | 0.15.2  | Provides network pools and load balancing for my homelab cluster.                                                                                                                                                                                        |
| `pihole`        | 2.34.0  | Provides a k3s-based pihole service, an open-source DNS-based ad-and-telemetry blocking service available on my LAN.                                                                                                                                     |
| `ingress-nginx` | 4.11.2  | Provides ingress for the cluster.                                                                                                                                                                                                                        |
| `external-dns`  | 1.18.0  | Provides external DNS registration for the pihole service, so that custom DNS entries (like `pihole.lab`) are resolvable when clients use pihole as a DNS server.                                                                                        |
| `postgres`      | 16.4.5  | [DISABLED] Provides a k3s-based Postgres DB instance for use in my homelab.                                                                                                                                                                              |
| `authentik`     | TBD     | [WIP] Provides a custom OIDC server for managing logins for various tools and services, so I can use my own domains and auth rather than a 3rd part identitdy provider (IdP), like GitHub, Google, or Microsoft.                                         |

## Basic Ops

### Running Deployments

Running deployments is as simple as a `helmfile apply`.
