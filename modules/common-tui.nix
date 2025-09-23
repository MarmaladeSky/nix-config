{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux

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
    # Javascript
    nodejs
    # Haskell
    stack
    # Python
    uv
  ];
}
