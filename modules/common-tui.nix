{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux
    jq

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

    # Networking
    frp
    wget

    # Development
    git
    neovim
    nixfmt
    awscli2
    # Javascript
    nodejs
    # Haskell
    stack
    # Python
    uv
  ];
}
