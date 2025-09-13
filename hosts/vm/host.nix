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
  networking.hostName = "vm";
  networking.networkmanager.enable = true;

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  services.openssh.enable = true;
  environment.systemPackages = with pkgs; [
  ];
}
