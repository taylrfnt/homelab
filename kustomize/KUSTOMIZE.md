# Kustomize

This directory holds cluster resources that are not installed by a Helm chart.
They are plain Kubernetes manifests combined by
[`kustomization.yaml`](./kustomization.yaml), which also adds the label
`app.kubernetes.io/managed-by: Kustomize` to every resource (including its
selectors).

## Resources

### MetalLB address pool

[`metallb/pool.yaml`](./metallb/pool.yaml) configures the MetalLB release from
[`helm/helmfile.yaml`](../helm/helmfile.yaml):

- `IPAddressPool` `pool` (namespace `metallb-system`): hands out
  `192.168.1.192/26` (192.168.1.192 – 192.168.1.255) to `type: LoadBalancer`
  Services.
- `L2Advertisement` `homelab`: announces addresses from `pool` over ARP
  (layer 2 mode).

Keep the router's DHCP range outside this block. Services that pin an address,
such as Pi-hole's `192.168.1.250` and `192.168.1.251`, must use an address in it.

## Applying

These resources depend on CRDs installed by the Helm releases, so run
`helmfile apply` in `helm/` first. Then, from the repository root:

```
kubectl diff -k kustomize    # preview changes
kubectl apply -k kustomize   # apply changes
```

## Adding a resource

1. Put the manifest in a subdirectory named after the component it belongs to,
   such as `metallb/`.
2. Add its path under `resources` in `kustomization.yaml`.
3. Check the rendered output with `kubectl kustomize kustomize`, then apply.
