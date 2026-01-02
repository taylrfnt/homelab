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
        tailscale-operator = {
          enable = true;
          source = config.sops.templates.tailscale-operator.path;
        };
        tailscale-subnet-router = {
          enable = true;
          source = ./manifests/tailscale-subnet-router.yaml;
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
        # this isn't working - need to debug.  plus, i think this leaves secrets in the store readable
        # tailscale-operator = {
        #   name = "tailscale-operator";
        #   repo = "https://pkgs.tailscale.com/helmcharts";
        #   version = "1.92.4";
        #   hash = "sha256:a64828964ee38b79448a54e52f5d819da2295ed10856de0c89414aa2e1fc7dc3";
        #   createNamespace = true;
        #   targetNamespace = "tailscale";
        #   values = config.sops.templates.tailscale-operator-values.path;
        # };
      };
    };

    openiscsi = {
      enable = true;
      name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
    };
  };
}
