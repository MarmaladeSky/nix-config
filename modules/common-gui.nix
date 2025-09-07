{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Images
    gimp

    # Web
    brave

    # Terminal
    sakura

    # Development
    dbeaver-bin
    jetbrains.datagrip
    jetbrains.goland
    jetbrains.idea-ultimate
    jetbrains.pycharm-professional
    jetbrains.rust-rover
    vscode

    # Communication
    telegram-desktop
  ];
}
