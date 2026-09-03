{
  config,
  pkgs,
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
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  time.timeZone = "UTC";
  networking.hostName = "huananzhi";

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."easytier-env" = {
      sopsFile = ../../secrets/easytier.env;
      format = "dotenv";
      owner = "root";
    };
  };

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "dialout"
      "libvirtd"
    ];
  };

  services = {
    easytier = {
      enable = true;
      instances.default = {
        settings = {
          hostname = "huananzhi";
          ipv4 = "10.1.1.4/24";
        };
        environmentFiles = [
          config.sops.secrets."easytier-env".path
        ];
      };
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      configDir = "/home/user/.config/syncthing";
      user = "user";
      group = "users";
      settings = {
        devices =
          let
            ids = {
              fw12 = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA";
              fw13 = "BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN";
              thinkpad = "CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2";
              pi = "DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH";
              huananzhi = "EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE";
            }
            // (
              if builtins.pathExists ../../syncthing-devices.nix then import ../../syncthing-devices.nix else { }
            );
          in
          {
            fw12.id = ids.fw12;
            fw13.id = ids.fw13;
            thinkpad.id = ids.thinkpad;
            pi.id = ids.pi;
            huananzhi.id = ids.huananzhi;
          };

        folders = {
          "Pictures" = {
            path = "/home/user/Pictures";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Documents" = {
            path = "/home/user/Documents";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Videos" = {
            path = "/home/user/Videos";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Music" = {
            path = "/home/user/Music";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
        };
      };
    };

    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      windowManager.awesome.enable = true;
      xkb.layout = "us,ru";
      xkb.variant = ",";
      xkb.options = "grp:caps_toggle";
    };
    displayManager.defaultSession = "none+awesome";
    picom.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    gvfs.enable = true;
    udisks2.enable = true;
  };

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

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
    nautilus
    pavucontrol
    pamixer
    arandr
    feh
    kubectl
    cloud-utils
    kubernetes-helm
    k9s
  ];
}
