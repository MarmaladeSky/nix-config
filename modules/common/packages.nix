{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    btop

    # Development
    git
    neovim
  ];
}
