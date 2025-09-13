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

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Window Management
    gnomeExtensions.touch-x
    gnome-tweaks
  ];
}
