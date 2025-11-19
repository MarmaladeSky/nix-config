{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [ (import "${home-manager}/nixos") ];

  # i3lock
  security.pam.services.i3lock = {
    enable = true;
    text = ''
      auth include login
      account include login
      password include login
      session include login
    '';
  };

  programs.waybar.enable = true;

  home-manager.users.user = { 

    home.packages = with pkgs; [
      # awesome
      pamixer
      picom
      pavucontrol
      acpilight
      i3lock-color
      networkmanagerapplet
      networkmanager-openvpn

      # hyprland
      rofi
      font-awesome
    ]; 

    home.file.".config/awesome".source = builtins.fetchGit {
      url = "https://github.com/MarmaladeSky/awesomewm.git";
      rev = "b64d4a0fcae1201d7ae43065331e75413a07d32d";
      submodules = true;
    };
  };
}

