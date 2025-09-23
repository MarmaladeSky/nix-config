{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "slack"
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
    ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "wpa_supplicant";
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  environment.systemPackages = with pkgs; [
    # Images
    gimp
    krita

    # Web
    brave

    # Files
    dropbox

    # Secrets
    (callPackage ../pkgs/revelation { })

    # Shell
    sakura
    xclip

    # Development
    dbeaver-bin
    (jetbrains.datagrip.override { jdk = pkgs.openjdk23; })
    (jetbrains.goland.override { jdk = pkgs.openjdk23; })
    (jetbrains.idea-ultimate.override { jdk = pkgs.openjdk23; })
    (jetbrains.pycharm-professional.override { jdk = pkgs.openjdk23; })
    (jetbrains.rust-rover.override { jdk = pkgs.openjdk23; })
    vscodium

    # Communication
    telegram-desktop
    slack
  ];
}
