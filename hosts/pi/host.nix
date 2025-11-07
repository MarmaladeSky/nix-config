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
    };

    immich = {
      enable = true;
      host = "0.0.0.0";
      port = 2283;
      mediaLocation = "/mnt/storage/immich";
      machine-learning.enable = false;
      database.enableVectorChord = false;
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
