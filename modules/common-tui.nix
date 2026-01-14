{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
  '';

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

    # Development
    git
    neovim
    nixfmt
    awscli2
    sqlite
    # Javascript
    nodejs
    # Haskell
    stack
    # Python
    uv
    # Java
    jdk25
    # Scala
    scala
    sbt
    mill
  ];
}
