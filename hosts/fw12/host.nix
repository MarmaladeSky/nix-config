{ pkgs, disko, ... }:
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

  time.timeZone = "UTC";
  networking.hostName = "fw12";
  networking.networkmanager.enable = true;

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  services = {
    fwupd.enable = true;

    desktopManager.gnome.enable = true;
    gnome = {
      core-apps.enable = false;
      core-developer-tools.enable = false;
      games.enable = false;
    };
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
      };
      windowManager.awesome.enable = true;
    };
  };
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

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
    gnomeExtensions.touch-x
    gnomeExtensions.appindicator
    gnome-tweaks
    nautilus # implicitly required by vscodium to open file dialogs

    # part of virtualization
    kubectl
    cloud-utils
    helm
  ];
}
