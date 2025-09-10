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
      home.packages = [ ];
      programs.fish.enable = true;
      users.users.user.shell = pkgs.fish;

      home.stateVersion = "25.05";
    };
}
