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

  programs.gnupg.agent.pinentryPackage = pkgs.writeShellScriptBin "pinentry" ''
    if [ "$PINENTRY_USER_DATA" = "tty" ]; then
      exec ${pkgs.pinentry-tty}/bin/pinentry-tty "$@"
    fi
    exec ${pkgs.pinentry-gtk2}/bin/pinentry-gtk-2 "$@"
  '';

  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "wpa_supplicant";
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openvpn
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        KernelExperimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
        MultiProfile = "multiple";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  services = {

    blueman.enable = true;

    pipewire.wireplumber.extraConfig."10-bluetooth" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
          "hfp_ag"
          "hfp_hf"
          "hsp_ag"
          "hsp_hs"
        ];
        "bluez5.codecs" = [
          "ldac"
          "aptx_hd"
          "aptx"
          "aac"
          "sbc_xq"
          "sbc"
        ];
      };
    };

    xserver.displayManager.sessionCommands = ''
      ${pkgs.blueman}/bin/blueman-applet &
    '';

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
    pinentry-gtk2

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
