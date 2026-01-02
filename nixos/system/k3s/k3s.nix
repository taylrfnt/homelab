{
  pkgs,
  config,
  meta,
  ...
}:
{
  imports = [
    ./sops.nix
  ];
  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  services = {
    k3s = {
      # k3s service config
      enable = true;
      package = pkgs.k3s;
      role = "server";
      tokenFile = config.sops.secrets."rancher/k3s/server/token".path;
      extraFlags = toString (
        [
          "--write-kubeconfig-mode \"0644\""
          "--cluster-init"
          "--disable local-storage"
        ]
        ++ (
          if meta.hostname == "homelab-0" then
            [ ]
          else
            [
              # replace homelab-0 with IP address, if router does not support custom DNS (naughty ISP)
              "--server https://192.168.1.64:6443"
            ]
        )
      );
      clusterInit = meta.hostname == "homelab-0";

      # manifests are used for secrets and other resources that do not have charts
      manifests = {
        # https://longhorn.io/docs/1.10.1/deploy/accessing-the-ui/longhorn-ingress/
        longhorn-ui-auth = {
          enable = true;
          source = config.sops.templates.longhorn-ui-auth.path;
        };
        longhorn-ui-ingress = {
          enable = true;
          source = ./manifests/longhorn-ingress.yaml;
        };
        # https://tailscale.com/kb/1185/kubernetes
        tailscale-auth = {
          enable = true;
          source = config.sops.templates.tailscale-auth.path;
        };
      };

      # for resources that have helm charts, use them
      autoDeployCharts = {
        longhorn = {
          name = "longhorn";
          repo = "https://charts.longhorn.io";
          version = "1.10.1";
          hash = "sha256:a871d397e19cf3243949abd41fd294869f5c2c490014f29e71866a2433ec7fb9";
          createNamespace = true;
          targetNamespace = "longhorn-system";
        };
      };
    };

    openiscsi = {
      enable = true;
      name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
    };
  };
}
