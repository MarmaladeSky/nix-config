{
  config,
  pkgs,
  home-manager,
  elkfarm,
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

      # utils
      elkfarm
      sops
      # the capture overlay must bypass the window manager, awesomewm places it
      # under the wibar otherwise
      (flameshot.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/widgets/capture/capturewidget.cpp \
            --replace-fail "if (DesktopInfo().waylandDetected()) {" "if (true) {"
        '';
      }))
    ];

    home.file.".config/awesome".source = builtins.fetchGit {
      url = "https://github.com/MarmaladeSky/awesomewm.git";
      rev = "d6320521583938711b04e33c7feb734792532f16";
      submodules = true;
    };

    # required by awesomewm
    home.file.".config/flameshot/flameshot.ini" = {
      force = true;
      text = ''
        [General]
        contrastOpacity=188
        useX11LegacyScreenshot=true
      '';
    };
  };
}
