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
      rev = "d6320521583938711b04e33c7feb734792532f16";
      submodules = true;
    };
  };
}

