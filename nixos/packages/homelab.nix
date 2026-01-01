{
  pkgs,
  # lib,
  ...
}:
let
  userPkgs = with pkgs; [
    eza
    tree
    oh-my-posh
    zsh-vi-mode
    zsh-autosuggestions
    kubernetes-helm
    helmfile
  ];
  globalPkgs = with pkgs; [
    cifs-utils
    nfs-utils
    git
    dig
    zsh
    keychain
    pass
    tailscale
    nh
    microfetch
    sops
    ssh-to-age
    yubikey-manager
    yubico-piv-tool
    age-plugin-yubikey
    ccid
  ];
in
{
  environment.systemPackages = globalPkgs;
  users.users.taylor = {
    packages = userPkgs;
  };
}
