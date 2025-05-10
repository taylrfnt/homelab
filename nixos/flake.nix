{
  description = "Homelab NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = {
    self,
    nixpkgs,
    disko,
    sops-nix,
    ...
  } @ inputs: let
    nodes = [
      "homelab-0"
      "homelab-1"
      "homelab-2"
    ];
  in {
    nixosConfigurations = builtins.listToAttrs (map (name: {
        name = name;
        value = nixpkgs.lib.nixosSystem {
          specialArgs = {
            meta = {hostname = name;};
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
      })
      nodes);
  };
}
