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
    qimgv

    # Web
    brave
    tor-browser
    freetube

    # Files
    dropbox
    xfce.thunar

    # Secrets
    (callPackage ../pkgs/revelation { })

    # Shell
    sakura
    xclip

    # Development
    dbeaver-bin
    (jetbrains.datagrip.override { jdk = pkgs.openjdk25; })
    (jetbrains.goland.override { jdk = pkgs.openjdk25; })
    (jetbrains.idea.override { jdk = pkgs.openjdk25; })
    (jetbrains.pycharm.override { jdk = pkgs.openjdk25; })
    (jetbrains.rust-rover.override { jdk = pkgs.openjdk25; })
    vscodium
    visualvm
    claude-code
    opencode
    flyway

    # Communication
    telegram-desktop
    slack
  ];
}
