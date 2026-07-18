{ pkgs, disko, ... }:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  system.stateVersion = "25.05";

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree = {
      enable = true;
    };
  };

  fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-label/storage";
    fsType = "btrfs";
    options = [ "nofail" "x-systemd.device-timeout=5s" ];
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.availableKernelModules = [ "xhci_pci" "usbhid" "usb_storage" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  time.timeZone = "UTC";
  networking.hostName = "raspberry";
  networking.networkmanager.enable = true;

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 2283 ];
    allowedUDPPortRanges = [];
  };

  services = {
    openssh.enable = true;

    postgresql = {
      enable = true;
      dataDir = "/mnt/storage/postgresql";
      # vectorchord is required by immich
      # it may be better to move DB management to immich itself
      # there was a huge pain of migrating from another vector search extension
      extensions = ps: with ps; [
        pgvector
        vectorchord
      ];
      settings = {
        shared_preload_libraries = "vchord.so";
      };
    };

    immich = {
      enable = true;
      host = "0.0.0.0";
      port = 2283;
      mediaLocation = "/mnt/storage/immich";
      machine-learning.enable = false;
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
            ids =
              if builtins.pathExists ../../syncthing-devices.nix then
                import ../../syncthing-devices.nix
              else
                {
                  fw12 = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA";
                  fw13 = "BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN";
                  thinkpad = "CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2";
                  pi = "DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH";
                };
          in
          {
            fw12.id = ids.fw12;
            fw13.id = ids.fw13;
            thinkpad.id = ids.thinkpad;
            pi.id = ids.pi;
          };

        folders = {
          "Pictures" = {
            path = "/mnt/storage/user/syncthing/Pictures";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
            ];
          };
        };
      };
    };
  };
  # Prepare the directory for PostgreSQL and Immich data
  system.activationScripts.postgresInit = {
  text = ''
    mkdir -p /mnt/storage/postgresql
    mkdir -p /mnt/storage/immich
    chown -R postgres:postgres /mnt/storage/postgresql
    chown -R immich:immich /mnt/storage/immich
  '';
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };


  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  users.users.mercury = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  environment.systemPackages = with pkgs; [
    # Raspberry Pi related
    libraspberrypi
    raspberrypi-eeprom
    toybox

    # HDD
    smartmontools
  ];
}
