{
  description = "Homelab NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # Disko
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    disko,
    sops-nix,
    nvf,
    hjem,
    ...
  } @ inputs: {
    nixosConfigurations = {
      "homelab-0" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          meta = {
            hostname = "homelab-0";
          };
          inherit inputs;
          pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        system = "x86_64-linux";
        modules = [
          # hardware scan & disko config
          ./hardware/hardware-configuration.nix
          disko.nixosModules.disko
          ./modules/disko/disko-config.nix
          ./system/homelab.nix
          ./packages/homelab.nix
          # nvf for (neo)vim
          nvf.nixosModules.default
          ./modules/nvf/default.nix
          # hjem for user home mgmt
          hjem.nixosModules.default
          {
            hjem.users.taylor = ./home/hjem/homelab.nix;
          }
          # sops for secrets
          sops-nix.nixosModules.sops
          ./modules/sops/homelab.nix
        ];
      };
      "homelab-1" = nixpkgs.lib.nixosSystem {
        specialArgs = {
          meta = {
            hostname = "homelab-1";
          };
          inherit inputs;
          pkgs-stable = import nixpkgs-stable {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
        };
        system = "x86_64-linux";
        modules = [
          # hardware scan & disko config
          ./hardware/hardware-configuration.nix
          disko.nixosModules.disko
          ./modules/disko/disko-config.nix
          ./system/homelab.nix
          ./packages/homelab.nix
          # nvf for (neo)vim
          nvf.nixosModules.default
          ./modules/nvf/default.nix
          # hjem for user home mgmt
          hjem.nixosModules.default
          {
            hjem.users.taylor = ./home/hjem/homelab.nix;
          }
          # sops for secrets
          sops-nix.nixosModules.sops
          ./modules/sops/homelab.nix
        ];
      };
    };
  };
}
