{
  pkgs,
  lib,
  disko,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  system.stateVersion = "25.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.logind.settings.Login.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';

  time.timeZone = "UTC";
  networking.hostName = "thinkpad";
  networking.networkmanager.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="backlight", ACTION=="add", \
    RUN+="${pkgs.coreutils}/bin/chgrp video /sys$devpath/brightness", \
    RUN+="${pkgs.coreutils}/bin/chmod g+w /sys$devpath/brightness"
  '';

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];
  };

  # somehow it gets enabled
  systemd.user.services.orca.enable = false;

  services = {
    fwupd.enable = true;

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      configDir = "/home/user/.config/syncthing";
      user = "user";
      group = "users";
      folders = {
        "Pictures" = {
	  path = "/home/user/Pictures";
	  ignorePerms = false;
	};
        "Documents" = {
	  path = "/home/user/Documents";
	  ignorePerms = false;
	};
        "Videos" = {
	  path = "/home/user/Videos";
	  ignorePerms = false;
	};
        "Music" = {
	  path = "/home/user/Music";
	  ignorePerms = false;
	};
      };
    };

    gnome = {
      core-apps.enable = false;
      core-developer-tools.enable = false;
      games.enable = false;
      gcr-ssh-agent.enable = false;
    };

    xserver = {
      enable = true;
      dpi = 166;
      displayManager = {
        lightdm.enable = false;
      };
      windowManager.awesome.enable = true;
      xkb.layout = "us,ru";
      xkb.variant = ",";
      xkb.options = "grp:caps_toggle";
    };
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
    };
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
    allowedBridges = [ "br0" ];
  };

  environment.systemPackages = with pkgs; [
    # Window Management
    gnomeExtensions.appindicator
    gnome-tweaks
    nautilus # implicitly required by vscodium to open file dialogs

    # part of virtualization
    kubectl
    cloud-utils
    kubernetes-helm
    k9s

    # Development
    # Scala
    bloop
  ];
}
