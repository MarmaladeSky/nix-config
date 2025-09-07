{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    # Shell
    tmux

    # File management
    mc

    # Monitoring
    htop
    btop

    # Development
    git
    neovim
    nixfmt
  ];
}
