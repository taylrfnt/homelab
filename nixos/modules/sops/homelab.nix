{
  sops = {
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    secrets."rancher/k3s/server/token" = {
      # path = "/var/lib/rancher/k3s/server/token";
    };
  };
}
