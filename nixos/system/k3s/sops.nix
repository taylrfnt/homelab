{ config, ... }:
{
  sops = {
    secrets = {
      "rancher/longhorn/ui/auth" = { };
      "tailscale/auth-key" = { };
    };
    templates = {
      "longhorn-ui-auth" = {
        content = ''
          apiVersion: v1
          kind: Secret
          metadata:
            name: longhorn-ui-auth
            namespace: longhorn-system
          type: Opaque
          data:
            auth: ${config.sops.placeholder."rancher/longhorn/ui/auth"}
        '';
      };
      "tailscale-auth" = {
        content = ''
          apiVersion: v1
          kind: Secret
          metadata:
            name: tailscale-auth
          stringData:
            TS_AUTHKEY: ${config.sops.placeholder."tailscale/auth-key"}
        '';
      };
    };
  };
}
