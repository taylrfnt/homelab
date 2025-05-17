# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  config,
  lib,
  pkgs,
  pkgs-stable,
  meta,
  ...
}: {
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc.automatic = true;
    # enable community cache for modules
    settings = {
      substituters = ["http://nix-community.cachix.org"];
      trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  networking = {
    hostName = meta.hostname; # Define your hostname.

    # Pick only one of the below networking options.
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    networkmanager.enable = true; # Easiest to use and most distros use this by default.
    # networkmanager.settings.connection."ipv4.method" = "auto";

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ 80 ];
    # networking.firewall.allowedUDPPorts = [ ... ];
    # Or disable the firewall altogether.
    firewall.enable = false;
  };

  programs.zsh.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
    #useXkbConfig = true; # use xkb.options in tty.
  };

  # Fixes for longhorn
  systemd.tmpfiles.rules = [
    "L+ /usr/local/bin - - - - /run/current-system/sw/bin/"
  ];
  virtualisation.docker.logDriver = "json-file";

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";
  services = {
    k3s = {
      enable = true;
      package = pkgs-stable.k3s;
      role = "server";
      tokenFile = config.sops.secrets."rancher/k3s/server/token".path;
      extraFlags = toString ([
          "--write-kubeconfig-mode \"0644\""
          "--cluster-init"
          "--disable servicelb"
          "--disable traefik"
          "--disable local-storage"
          "--prefer-bundled-bin"
        ]
        ++ (
          if meta.hostname == "homelab-0"
          then []
          else [
            # replace homelab-0 with IP address, if router does not support custom DNS (naughty ISP)
            "--server https://192.168.1.64:6443"
          ]
        ));
      clusterInit = meta.hostname == "homelab-0";
    };

    openiscsi = {
      enable = true;
      name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
    };

    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      banner = "\n   _                 _     _ \n  | |_ ___ _____ ___| |___| |_\n  |   | . |     | -_| | .'| . |\n  |_|_|___|_|_|_|___|_|__,|___|\n\n Welcome to homelab.\n\n";
    };
  };

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.taylor = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    # Created using mkpasswd
    hashedPassword = "$6$QHI78ky1rOZZkAOh$FCRwbkcpLynrwzuQ1shI6q5s3xav7ipfp4voxWxNZM7SKR5ga7RWhcmWPpFfb0jmTXObd39mvG9I.h4n3XJZx1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB8wB5rMU+3zBLjdzq4E4ziK74XTyPEqLRoiMmI7UbJ4 taylor@amaterasu"
    ];
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.ssh.startAgent = true;
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

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
