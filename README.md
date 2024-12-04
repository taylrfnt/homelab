# TODO
1. Better formatting for `*.nix` files (e.g. merge all `services.{value}` into sinle `services = {}` block)
2. Nest configs for flakes (e.g. SSH banner, daemon, etc.) rather than modify main config

# Homelab
## Cluster Specs
homelab uses the following specs (updated as homelab grows)
### Hardware
**homelab-0**
* Beelink EQ13
  * CPU: Intel 12th Gen (Ader Lake) N100
  * RAM: 16GB DDR4
  * Storage: 500 GB PCIE3.0 SSD

**homelab-1**
* N/A

**homelab-2**
* N/A

### Software/OS
**homelab-0**
* NixOS 24.05.20240930.1719f27 (Uakari)
    * nixpkgs = `unstable`
    * extra-experimental-features = `nix-command flakes`
* k3s v1.30.4+k3s1

**homelab-1**
* N/A

**homelab-2**
* N/A

## Managing homelab
### Configuration
homelab configuration has been written declaratively in the `nixos` directory.  Modifying the configuration will work exactly like any
NixOS machine.  **The homelab does not use home manager!!**

### Rebuilding homelab flakes
If you find a need to modify homelab configurations, you will need to rebuild each flake.  There are two options to rebuild your flakes.

**Option 1: Direct SSH & Vanilla Nix**
A rebuild can be initiated by opening a remote
SSH session into each host and running the following command per host:
```
❯ sudo nixos-rebuild switch --flake /path/to/config#<flake-name>
```
The flake names will be `homelab-0`, `homelab-1`, and `homelab-2`, repsectively.

**Option 2: `nixos-anywhere`**
Alternatively, you can use [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) to remotely rebuild and push new flakes.
In this method, you will simply need a copy of the configurations you wish to apply to homelab and be within the same network as the
target node(s).

Run the following command, injecting the proper user/host values for each node:
```
 sudo nix run github:nix-community/nixos-anywhere \
--extra-experimental-features "nix-command flakes" \
--build-on-remote \
-- -- flake '/path/to/config#<flake-name>' <user>@<host>
```
**_NOTE_**
* The `--build-on-remote` flag is not strictly required in all cases; however, if you omit it you must have a machine capable of builing derivations for the target system.  This is an issue if your host machine uses an architecture different than the target (e.g. `aarch64-darwin` host building for an `x86-64` system).  In such cases, Option 1 is likley the easier of the two.

### Managing homelab deployments
homelab runs a kubernetes (k3s) cluster that is enabled with several features, such as storage managament (via `longhorn`),
load balancing (via `metallb`), and DNS configurations.  As with any kuberenetes-based platform, you can SSH into specific nodes
to interact with the control plane; however, it is not necessary.

To manage homelab, you will need the following installed on your host machine:
* kubectl
* kustomize
* helm* (installed via helmfile)
* helmfile

Assuming you have all of the relevant prequisite packages installed, there are a few simple steps to get started accessing
homelab via your host machine:
1. Confirm you have a key that can be used to connect to one of more of the nodes via `ssh`.
  * The authorized public keys for each node (Nix flake) are contained within the `users.users.<name>.openssh.authorizedKeys.keys`
  attribute within the `configuration.nix`.
  * **NOTE**: You should update key entries with a new public key for your host machine (and remove any old keys), then rebuild the flake
  if you are accessing homelab from a new machine for the first time.  Sharing keys between hosts is a poor security practice.
2. Copy down the `k3s.yaml` file which defines the cluster specs and certificates from homelab to your host machine into `~/.kube/config`:
```
❯ scp -r <user>@<host>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```
3. Modify the `server` entry in your newly created `~/.kube/config` to use the hostname/IP of your control host, rather than `localhost`:
_Unmodified entry_:
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: [...]
    server: https://localhost:6443  <-----------
  name: default
contexts:
```
_Modified entry_:
```
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: [...]
    server: https://homelab-0:6443  <-----------
  name: default
contexts:
```
4. You can now test your setup by issuing a `kubectl` command:
```
❯ kubectl get nodes
NAME        STATUS   ROLES                       AGE   VERSION
homelab-0   Ready    control-plane,etcd,master   63d   v1.30.4+k3s1

```
* Pro tip: aliasing `kubectl` to `k` in your profile greatly reduces the number of keystrokes invovled with managing
a k3s cluster.

## Restart homelab k3s (gracefully)

### Adding new nodes to homelab

## References
homelab was built intially by following along with [Elliott at Dreams of Autonomy](https://youtu.be/2yplBzPCghA).
Many of the charts and configurations are quite similar (if not identical in some cases), with customizations specifically for
my own hardware and use cases.

