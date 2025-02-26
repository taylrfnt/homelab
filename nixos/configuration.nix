# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, meta, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
    ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = meta.hostname; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
  networking.networkmanager.settings.connection."ipv4.method" = "auto";

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
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = /var/lib/rancher/k3s/server/token;
    extraFlags = toString ([
	    "--write-kubeconfig-mode \"0644\""
	    "--cluster-init"
	    "--disable servicelb"
	    "--disable traefik"
	    "--disable local-storage"
    ] ++ (if meta.hostname == "homelab-0" then [] else [
	      "--server https://homelab-0:6443"
    ]));
    clusterInit = (meta.hostname == "homelab-0");
  };

  services.openiscsi = {
    enable = true;
    name = "iqn.2016-04.com.open-iscsi:${meta.hostname}";
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
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    shell = pkgs.zsh;
    packages = with pkgs; [
      tree
      fastfetch
    ];
    # Created using mkpasswd
    hashedPassword = "$6$QHI78ky1rOZZkAOh$FCRwbkcpLynrwzuQ1shI6q5s3xav7ipfp4voxWxNZM7SKR5ga7RWhcmWPpFfb0jmTXObd39mvG9I.h4n3XJZx1";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDXAM2ekfY3J6RvvGzI7KgrmzOHUs/AuxS9+7yqppC87OKE6Gu7XlGukgvroyT1QGvvND9AB2YMd8ddGt96WzJnFWsKCVlu3n+3N4MeaM3bSXxouvc/Tse/dZ2noltzJ14WlQelOMgEpFBMUUd8pOOpAJrrpuF/7i44myrzqzEWTI1IdM60w6IXq6T0k/4nnBJNnpMiTSDBBdM+f5on2GCKwMB9NL05Elok32dLAnEIdFh+jlznq9fu+sMgAUeTnPAjibPwTNfrZN9dfzssp5oyz28K0Ffk17IJvwQlc5RjuBl5iCpd7ST2xDvpQsSSJdSJ7JE+/OeBTaA6R0bS6heBH+ojQgFJ+6NDlfoMSVSInnbSUWhK82D5zDJiQIdd/UXD9W6MDcDvPNa+/25qExhODl7Rx0EsI8zMTuQqM2gCfBt5inRiwCQrbECEDp6ROIP0gmJ+Z0CUytxDQznf3tN1WI/j+smlhyaazetaW3558E30DvrUHHSxq49/vEvmpE0= amaterasu access key"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     neovim
     k3s
     cifs-utils
     nfs-utils
     git
     dig
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.banner = "\n   _                 _     _ \n  | |_ ___ _____ ___| |___| |_\n  |   | . |     | -_| | .'| . |\n  |_|_|___|_|_|_|___|_|__,|___|\n\n Welcome to homelab.\n\n";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ 80 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

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

