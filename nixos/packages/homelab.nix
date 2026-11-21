{
  pkgs,
  lib,
  inputs,
  ...
}:
let
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
    nh
  ];
in
{
  nixpkgs.config.allowUnfreePredicate = 
    pkg: 
    builtins.elem (lib.getName pkg) [
┃     "copilot-language-server"
┃   ];
  environment.systemPackages = globalPkgs;
  users.users.taylor = {
    packages = userPkgs;
  };
}
