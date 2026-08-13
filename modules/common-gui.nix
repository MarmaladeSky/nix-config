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

  # Claude Code global instructions
  systemd.tmpfiles.rules = [
    "d /home/user/.claude-personal 0755 user users -"
    "d /home/user/.claude-work 0755 user users -"
  ];

  sops.secrets = {
    "claude-personal-md" = {
      sopsFile = ../secrets/claude-personal.md;
      format = "binary";
      owner = "user";
      path = "/home/user/.claude-personal/CLAUDE.md";
    };
    "claude-work-md" = {
      sopsFile = ../secrets/claude-work.md;
      format = "binary";
      owner = "user";
      path = "/home/user/.claude-work/CLAUDE.md";
    };
  };

  environment.systemPackages = with pkgs; [
    # Images
    gimp
    #krita disable krita due to broken dependency at 02/25/2026
    qimgv

    # Web
    brave-origin
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
