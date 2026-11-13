{
  pkgs,
  disko,
  modulesPath,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
    (modulesPath + "/profiles/all-hardware.nix")
    ./disko.nix
  ];

  system.stateVersion = "25.05";
  nixpkgs.hostPlatform = "x86_64-linux";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  boot.loader.efi.canTouchEfiVariables = false;

  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.graphics.enable = true;

  zramSwap.enable = true;

  time.timeZone = "UTC";
  networking.hostName = "liveusb";

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "dialout"
    ];
  };

  services = {
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

  environment.systemPackages = with pkgs; [
    nautilus
    arandr
    feh
  ];
}
