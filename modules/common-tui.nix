{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
  '';

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux
    jq
    yq-go

    # File management
    mc
    zip
    unzip

    # System
    htop
    btop
    pciutils
    efibootmgr
    mokutil

    # Encryption
    gnupg

    # Media
    mpv
    vlc

    # Utils
    flameshot

    # Networking
    frp
    wget
    sshfs
    qbittorrent-enhanced
    aerc

    # Development
    git
    nixfmt
    awscli2
    sqlite
    # Javascript
    nodejs
    # Haskell
    stack
    # Python
    python3
    uv
    # Java
    jdk17
    jdk25
    # Scala
    scala
    sbt
    mill
  ];
}
