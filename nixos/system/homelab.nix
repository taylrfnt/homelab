# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  pkgs,
  meta,
  ...
}:
{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc.automatic = true;
    settings = {
      # enable community cache for modules
      substituters = [ "http://nix-community.cachix.org" ];
      trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
    };
  };

  imports = [
    ./k3s/k3s.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
    };
  };

  networking = {
    hostName = meta.hostname; # Define your hostname.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
    firewall.enable = false;
  };

  programs.zsh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  services = {
    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      banner = builtins.readFile ./ssh/banner.txt;
    };
    pcscd = {
      enable = true;
      plugins = [
        pkgs.ccid
      ];
    };
    tailscale = {
      enable = true;
      # TODO:
      # authKeyFile = "/run/secrets/tailscale_key";
    };
  };

  users.users = {
    taylor = {
      isNormalUser = true;
      extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      shell = pkgs.zsh;
      # Created using mkpasswd
      hashedPassword = "$6$QHI78ky1rOZZkAOh$FCRwbkcpLynrwzuQ1shI6q5s3xav7ipfp4voxWxNZM7SKR5ga7RWhcmWPpFfb0jmTXObd39mvG9I.h4n3XJZx1";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDIIgS4ijWFQSsH+icfod1IdPThAbmgl4zEF/zn9/vOG bw"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIE3+mtLkwVSoE9ruuWDmzXH6XvsvjrXQ5E/Hjg1gmcV3AAAAD3NzaDp1c2VyX3RheWxvcg== blue key"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPbS9n6TIPuk9WwvMc+uq6eWIoiOKTbwtEZ+E2DC03aPAAAAD3NzaDp1c2VyX3RheWxvcg== green key"
      ];
    };
    # root = {
    #   openssh.authorizedKeys.keys = [
    #     "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2TxJaavyg2CARn1kHa+eiLlC6NQrfKw+VlyPCrCVrT bw"
    #   ];
    # };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}
