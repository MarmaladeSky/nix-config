{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
  '';

  programs.neovim = {
    enable = true;
    withRuby = false;
    withPython3 = true;
    defaultEditor = true;
  };

  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      nerd-fonts.symbols-only
    ];
  };

  programs.gnupg = {
    agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-tty;
    };
  };

  services.openssh.enable = true;

  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux
    jq
    yq-go

    # File management
    mc
    zip
    unzip
    libimobiledevice
    ifuse

    # System
    htop
    btop
    pciutils
    usbutils
    efibootmgr
    mokutil
    exfat

    # Encryption
    gnupg
    pinentry-tty

    # Networking
    frp
    wget
    sshfs
    weechat
    nettools

    # Development
    git
    gitui
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
    # Zig
    zig
  ];
}
