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

    # Printing
    system-config-printer

    # Printing
    system-config-printer

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
    (flameshot.overrideAttrs (_: {
      version = "13.3.0";
      src = fetchFromGitHub {
        owner = "flameshot-org";
        repo = "flameshot";
        tag = "v13.3.0";
        hash = "sha256-RyoLniRmJRinLUwgmaA4RprYAVHnoPxCP9LyhHfUPe0=";
      };
      patches = map fetchurl [
        {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/31aea8e5e02750901de1e8bc0a30325d79ed10d7/pkgs/by-name/fl/flameshot/load-missing-deps.patch";
          hash = "sha256-XbuuoOiRDcS6XtCv0Uama5F166272FcmCxtwFMxl9sw=";
        }
        {
          url = "https://raw.githubusercontent.com/NixOS/nixpkgs/31aea8e5e02750901de1e8bc0a30325d79ed10d7/pkgs/by-name/fl/flameshot/macos-build.patch";
          hash = "sha256-VVQq2GfESWWADkSLILZuyCxHVSnQhDJl1+9C+zqEVFg=";
        }
      ];
    }))

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
    sox
    codex
    opencode
    flyway

    # Communication
    telegram-desktop
    slack
  ];
}
