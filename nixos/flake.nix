{
  description = "Homelab NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    disko,
    sops-nix,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "homelab-0" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          meta = {
            hostname = "homelab-0";
            inherit inputs;
          };
        };
        system = "x86_64-linux";
        modules = [
          # Modules
          disko.nixosModules.disko
          ./hardware-configuration.nix
          ./disko-config.nix
          sops-nix.nixosModules.sops
          ./configuration.nix
        ];
      };
    };
  };
}
