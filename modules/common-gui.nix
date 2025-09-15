{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Images
    gimp

    # Web
    brave

    # Files
    dropbox

    # Secrets
    (callPackage ../pkgs/revelation { })

    # Shell
    sakura
    xclip

    # Development
    dbeaver-bin
    (jetbrains.datagrip.override { jdk = pkgs.openjdk23; })
    (jetbrains.goland.override { jdk = pkgs.openjdk23; })
    (jetbrains.idea-ultimate.override { jdk = pkgs.openjdk23; })
    (jetbrains.pycharm-professional.override { jdk = pkgs.openjdk23; })
    (jetbrains.rust-rover.override { jdk = pkgs.openjdk23; })
    vscodium

    # Communication
    telegram-desktop
  ];
}
