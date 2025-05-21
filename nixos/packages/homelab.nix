{
  pkgs,
  # lib,
  ...
}: let
  userPkgs = with pkgs; [
    eza
    tree
    fastfetch
    oh-my-posh
    zsh-vi-mode
    zsh-autosuggestions
  ];
  globalPkgs = with pkgs; [
    cifs-utils
    nfs-utils
    git
    dig
    zsh
    keychain
  ];
in {
  environment.systemPackages = globalPkgs;
  users.users.taylor = {
    packages = userPkgs;
  };
}
