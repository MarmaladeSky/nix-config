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

  services = {

    printing = {
      enable = true;

      drivers = with pkgs; [
        cups-filters
        gutenprint
        brlaser
      ];

      browsed.enable = false;
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

  };

  environment.systemPackages = with pkgs; [
    # Images
    gimp
    #krita disable krita due to broken dependency at 02/25/2026
    qimgv

    # Web
    brave
    tor-browser
    freetube
    thunderbird
    claws-mail
    evolution

    # Printing
    system-config-printer

    # Networking
    qbittorrent-enhanced

    # Files
    dropbox
    thunar
    tumbler
    libreoffice

    # Secrets
    (callPackage ../pkgs/revelation { })

    # Media
    mpv
    vlc

    # Utils
    flameshot

    # Shell
    sakura
    xclip

    # Development
    dbeaver-bin
    jetbrains.datagrip
    jetbrains.goland
    jetbrains.idea
    jetbrains.pycharm
    jetbrains.rust-rover
    vscodium
    visualvm
    claude-code
    (writeShellScriptBin "claude-personal" ''
      CLAUDE_CONFIG_DIR="$HOME/.claude-personal" exec ${lib.getExe claude-code} "$@"
    '')
    (writeShellScriptBin "claude-work" ''
      CLAUDE_CONFIG_DIR="$HOME/.claude-work" exec ${lib.getExe claude-code} "$@"
    '')
    sox
    codex
    opencode
    flyway

    # Communication
    telegram-desktop
    slack
  ];
}
