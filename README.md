# Homelab

This repo is a self-contained collection of various configurations used to manage my homelab cluster.  The homelab is a multi-node k3s cluster managed via helm running on NixOS server hosts.  It's declarative (almost) all the way down.  

The homelab hosts a few important services I use frequently, like Pi-hole and (occasionally) a PostgreSQL database instance I can develop against in the comfort of my home network before going out to those expensive cloud hosts.

## Getting started

>[!IMPORTANT]
>You will need:
> - A machine with `nix` already installed (NixOS or otherwise)
> - At least one target machine you wish to install NixOS and your flake on.

1. Create a bootable USB using the latest NixOS Minimal ISO from [the NixOS downloads page](https://nixos.org/download/#nixos-iso).
2. Plug in the USB to your desired target machine (an old PC, server hosts, etc.) that you wish to run the homelab on.
3. Power on the machine, holding or pressing the keys you need to reach the boot menu.  For Beelink mini PCs, you need to repeatedly press <kbd>F7</kbd> to get to the boot menu.
4. Select your USB from the boot menu, and you should reach the basic TTY after about a minute, as the user `nixos`.
5. Switch to the `root` user using `sudo -i` and set a password using `passwd`.  **This is a temporary action on the bootable image only!  We're going to replace the entire system with our flake in the next few steps.**
6. Note the IP address of your target machine using `ip addr`.
7. Log into your other machine (any machine with the `nix` package manager installed).  Make sure you have this configuration set cloned (or your own) and use `nixos-anywhere` to reformat your disk(s), install NixOS, and switch to your flake configurations:
```
nix run github:nix-community/nixos-anywhere -- --flake /path/to/flake.nix#<configuration-name> --target-host root@your-IP
```
⚠️ **WARNING**
Sometimes `nixos-anywhere` will try to build on your local rather than your remote.  In most cases this is probably a good thing, since your main machine likely has more power to contribute to building your system.  However, in certain cases, the source platform/architecture is not compatible with the target (like using macOS/aarch-darwin with an x86 Intel target).  `nixos-anywhere` should detect this, but you can supply the `--build-on remote` option to force a build on your remote server.
8. Your target machine will reboot after the install succeeds, and you should be able to log to the remote in via SSH using your normal user & password (or identity file)!  From here on out, you can use the remote machine directly for flake updates & configuration changes.

## Configuration

TODO: re-write

## Secrets Management

## Keep the lights on

### Adding new nodes to the cluster

Adding a new node is simple - follow the process listed in the
["Getting started"](https://github.com/taylrfnt/homelab/blob/main/README.md#getting-started)
section.

A few important changes will be needed:
- A new age key will need to be created and added to the sops-nix configuration in
`.sops.yaml` for the new server to enable secret access (which is required for a
new node to join the k3s cluster).
- A new configuration set (e.g. `homelab-2`) needs to be added to the `flake.nix` and used when running `nixos-anywhere`.

All other configurations should "just work."

### Managing k3s deployments in the homelab cluster

homelab runs a kubernetes (k3s) cluster that is enabled with several features,
such as storage managament (via `longhorn`), load balancing (via `metallb`), and
DNS configurations. As with any kuberenetes-based platform, you can SSH into
specific nodes to interact with the control plane; however, it is not necessary.

To manage homelab, you will need the following installed on your host machine:

- kubectl
- kustomize
- helm* (dependency of helmfile)
- helmfile

Assuming you have all of the relevant prequisite packages installed, there are a
few simple steps to get started accessing homelab via your host machine:

1. Confirm you have a key that can be used to connect to one of more of the
   nodes via `ssh`.

- The authorized public keys for each node (Nix flake) are contained within the
  `users.users.<name>.openssh.authorizedKeys.keys` attribute within the
  `configuration.nix`.
- **NOTE**: You should update key entries with a new public key for your host
  machine (and remove any old keys), then rebuild the flake if you are accessing
  homelab from a new machine for the first time. Sharing keys between hosts is a
  poor security practice.

2. Copy down the `k3s.yaml` file which defines the cluster specs and
   certificates from homelab to your host machine into `~/.kube/config`:

```
❯ scp -r <user>@<host>:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```

3. Modify the `server` entry in your newly created `~/.kube/config` to use the
   hostname/IP of your control host, rather than `localhost`: _Unmodified
   entry_:

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

> [!TIP]
> Aliasing `kubectl` to `k` in your profile greatly reduces the number of
> keystrokes invovled with managing a k3s cluster.

### Updating deployments

homelab uses helmfile (and helm charts) as well as kustomize for managing k3s
resources. If you need to update or manage a k3s deployment, you will need to
modify the respective helmchart and values appropriately, then run a simple
apply:

```
helmfile apply
```

### Restart homelab k3s (gracefully)

k3s will not always gracefully recover in the event of an unepxected
interruption (e.g. power surge or a host being uplugged). However,
planned/manual changes should not impact the cluster health if proper procedure
is followed.

Should you need to take a node down for maintenance or recover it, an easy way
to do this is listed below.

1. SSH into the host you wish to take down.
2. Issue the respective [k3s stop command](https://docs.k3s.io/upgrades/killall)
   needed for your use case.
3. Perform upgrades/make changes needed.
4. Restart k3s using the appropriate
   [restart command](https://docs.k3s.io/upgrades/killall). You should not need
   to re-create the cluster.

## References

homelab was built intially by following along with
[Elliott at Dreams of Autonomy](https://youtu.be/2yplBzPCghA). Many of the
charts and configurations are quite similar (if not identical in some cases),
with customizations specifically for my own hardware and use cases.
