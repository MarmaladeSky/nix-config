{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [ (import "${home-manager}/nixos") ];
  users.users.user.isNormalUser = true;
  users.users.user.shell = pkgs.fish;
  home-manager.users.user =
    { pkgs, ... }:
    {
      home.packages = [ ];
      programs.fish.enable = true;

      home.stateVersion = "25.05";
    };
}
