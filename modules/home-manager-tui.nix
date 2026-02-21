{
  config,
  pkgs,
  home-manager,
  ...
}:
{
  users.users.user.isNormalUser = true;
  users.users.user.shell = pkgs.fish;
  home-manager.users.user =
    { pkgs, ... }:
    {
      home.packages = [ ];
      programs.fish.enable = true;

      # NeoVim
      programs.neovim = {
        enable = true;

	plugins = with pkgs.vimPlugins; [
	];

        extraConfig = ''
          set number
          set relativenumber
        '';

      };

      programs.git = {
        enable = true;

        aliases = {
          lg = '' log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all'';
        };
      };

      home.stateVersion = "25.05";
    };
}

