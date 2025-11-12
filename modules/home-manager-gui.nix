{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [ (import "${home-manager}/nixos") ];

  home-manager.users.user = { 

    home.packages = with pkgs; [
      pamixer
      picom
      pavucontrol
      acpilight
    ]; 

    home.file.".config/awesome".source = builtins.fetchGit {
      url = "https://github.com/MarmaladeSky/awesomewm.git";
      rev = "b64d4a0fcae1201d7ae43065331e75413a07d32d";
      submodules = true;
    };
  };
}

