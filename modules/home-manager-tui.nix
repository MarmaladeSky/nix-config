{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [ (import "${home-manager}/nixos") ];
  users.users.user.isNormalUser = true;
  home-manager.users.user =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.atool
        pkgs.httpie
      ];
      programs.fish.enable = true;

      home.stateVersion = "25.05";
    };
}
