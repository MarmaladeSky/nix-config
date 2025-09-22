{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

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

    # Networking
    frp

    # Development
    git
    neovim
    nixfmt
    nodejs
  ];
}
