{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux

    # File management
    mc

    # System
    htop
    btop
    pciutils

    # Development
    git
    neovim
    nixfmt
    nodejs
  ];
}
