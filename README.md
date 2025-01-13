# TODO
1. Better formatting for `*.nix` files (e.g. merge all `services.{value}` into sinle `services = {}` block)
2. Nest configs for flakes (e.g. SSH banner, daemon, etc.) rather than modify main config
3. Externalize k3s token without needing to scp private files to new hosts.

# Homelab
## Cluster Specs
homelab uses the following specs (updated as homelab grows)
### Hardware
| HOST      | MODEL        | CPU                              | RAM       | STORAGE            |
|-----------|--------------|----------------------------------|-----------|--------------------|
| homelab-0 | Beelink EQ13 | Intel 12th Gen (Alder Lake) N100 | 16GB DDR4 | 500 GB PCIE3.0 SSD |
| homelab-1 | Beelink EQ13 | Intel 12th Gen (Alder Lake) N100 | 16GB DDR4 | 500 GB PCIE3.0 SSD |
| homelab-2 | N/A          |                                  |           |                    |

### Software/OS
| Host      | NIXOS                           | NIXPKGS    | EXTRA FEATURES       | K3S          |
|-----------|---------------------------------|------------|----------------------|--------------|
| homelab-0 | 24.05.20240930.1719f27 (Uakari) | `unstable` | `nix-command flakes` | v1.30.4+k3s1 |
| homelab-1 | 24.05.20240930.1719f27 (Uakari) | `unstable` | `nix-command flakes` | v1.30.4+k3s1 |
| homelab-2 | N/A                             |            |                      |              |

## Getting started
### Configuration
homelab configuration has been written declaratively in the `nixos` directory.  Modifying the configuration will work exactly like any
NixOS machine.  **The homelab does not use home manager!!**

### Adding new nodes to the cluster
Adding a new node is simple - follow the process listed in Option 2 of the ["(Re)building homelab flakes"](https://github.com/taylrfnt/homelab/blob/main/README.md#rebuilding-homelab-flakes) section below.

The only change needed will be to overwrite the `services.k3s.tokenFile` entry with a plaintext `services.k3s.token` locally with the k3s
token, since the token file will not exist on an brand new/out-of-box environment.  All other configurations should work as-is.

## Managing homelab
### (Re)building homelab flakes
If you find a need to modify homelab configurations, you will need to rebuild each flake.  There are two options to (re)build your flakes.

**Option 1: Direct SSH & Vanilla Nix (requires an existing NixOS system)**
A rebuild can be initiated by opening a remote SSH session into each host, if they are already running NixOS.  To perform the system build
this way, you will need to clone this repo:
```
git clone <repo url> ~/homelab
```
Once the repo is cloned, running the following command per host:
```
❯ sudo nixos-rebuild switch --flake ~/homelab/nixos#<flake-name>
```
The flake names will be `homelab-0`, `homelab-1`, and `homelab-2`, repsectively.

**Option 2: `nixos-anywhere`**
Alternatively, you can use [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere) to remotely rebuild and push new flakes.
In this method, you need to nly have a bootable USB for NixOS to run on, boot it, and create a password for the `nixos` user.  After that,
you will simply need a copy of the configurations (files in this repo) you wish to apply to homelab and be able to SSH into the target node(s).

Run the following command, injecting the proper user/host values for each node:
```
nix run github:nix-community/nixos-anywhere \
--extra-experimental-features "nix-command flakes" \
--build-on-remote \
-- -- flake '/path/to/config#<flake-name>' nixos@<host>
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
* helm* (dependency of helmfile)
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

### Updating deployments
homelab uses helmfile (and helm charts) as well as kustomize for managing k3s resources.  If you need to update or manage
a k3s deployment, you will need to modify the respective helmchart and values appropriately, then run a simple apply:
```
helmfile apply
```

### Restart homelab k3s (gracefully)
k3s will not always gracefully recover in the event of an unepxected interruption (e.g. power surge or a host being uplugged).  However,
planned/manual changes should not impact the cluster health if proper procedure is followed.

Should you need to take a node down for maintenance or recover it, an easy way to do this is listed below.
1. SSH into the host you wish to take down.
2. Issue the respective [k3s stop command](https://docs.k3s.io/upgrades/killall) needed for your use case.
3. Perform upgrades/make changes needed.
4. Restart k3s using the appropriate [restart command](https://docs.k3s.io/upgrades/killall).  You should not need to re-create the
cluster; however, if you do find a need to re-create the homelab cluster from scratch, start with homelab-0.

### Rebuilding homelab's k3s cluster from scratch
Don't do this.  Please.

### Adding new nodes to homelab
To add a new node to the homelab cluster, ensure they are wired together via CAT5 cable (to share LAN) and have NixOS installed and
running.

You can use a simple `git` clone of this repo to fetch the baseline homelab configs (provided the new host has the same hardware specs), copy/modify them for the new host, and run a Nix rebuild.  Alternatively, you can use `nixos-anywhere`, if that is your preference.

The flake configuration for homelab is set to auto-join existing an existing cluster, provided the k3s token file is present.  If you use `nixos-anywhere`, you can run it from one of the existing nodes to build the target derivations without needing to copy the file, otherwise you should copy the file from an existing host to the new host machine to run a vanilla Nix flake rebuild.

## References
homelab was built intially by following along with [Elliott at Dreams of Autonomy](https://youtu.be/2yplBzPCghA).
Many of the charts and configurations are quite similar (if not identical in some cases), with customizations specifically for
my own hardware and use cases.

