{
  config,
  pkgs,
  lib,
  disko,
  noctalia-shell,
  ...
}:
{
  imports = [
    disko.nixosModules.disko
    ./disko.nix
  ];

  system.stateVersion = "25.05";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  services.logind.settings.Login.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';

  time.timeZone = "UTC";
  networking.hostName = "fw12";
  networking.networkmanager.enable = true;

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."easytier-env" = {
      sopsFile = ../../secrets/easytier.env;
      format = "dotenv";
      owner = "root";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="backlight", ACTION=="add", \
    RUN+="${pkgs.coreutils}/bin/chgrp video /sys$devpath/brightness", \
    RUN+="${pkgs.coreutils}/bin/chmod g+w /sys$devpath/brightness"
  '';

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
      "dialout"
    ];
  };

  # somehow it gets enabled
  systemd.user.services.orca.enable = false;

  services = {
    fwupd.enable = true;

    power-profiles-daemon.enable = false;
    auto-cpufreq.enable = true;

    easytier = {
      enable = true;
      instances.default = {
        settings = {
          hostname = "fw12";
          ipv4 = "10.1.1.2/24";
        };
        environmentFiles = [
          config.sops.secrets."easytier-env".path
        ];
      };
    };

    syncthing = {
      enable = true;
      openDefaultPorts = true;
      configDir = "/home/user/.config/syncthing";
      user = "user";
      group = "users";
      settings = {
        folders = {
          "Pictures" = {
            path = "/home/user/Pictures";
            ignorePerms = false;
          };
          "Documents" = {
            path = "/home/user/Documents";
            ignorePerms = false;
          };
          "Videos" = {
            path = "/home/user/Videos";
            ignorePerms = false;
          };
          "Music" = {
            path = "/home/user/Music";
            ignorePerms = false;
          };
        };
      };
    };

    gnome = {
      core-apps.enable = false;
      core-developer-tools.enable = false;
      games.enable = false;
      gcr-ssh-agent.enable = false;
    };

    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      windowManager.awesome.enable = true;
      xkb.layout = "us,ru";
      xkb.variant = ",";
      xkb.options = "grp:caps_toggle";
    };
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  # niri
  programs.niri.enable = true;
  home-manager.users.user.home.file.".config/niri/config.kdl".text = ''
    spawn-at-startup "noctalia"
    spawn-at-startup "xwayland-satellite" ":69"

    environment {
        DISPLAY ":69"
    }

    prefer-no-csd

    screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

    animations {
        off
    }

    input {
        keyboard {
            xkb {
                layout "us,ru"
                options "grp:caps_toggle"
            }
        }
        touchpad {
            tap
        }
        focus-follows-mouse
    }

    layout {
        gaps 0
        default-column-width { proportion 0.5; }
        focus-ring {
            off
        }
        border {
            off
        }
        struts {
            left 0
            right 0
            top 0
            bottom 0
        }
    }

    output "eDP-1" {
        scale 1
    }

    binds {
        Mod+Shift+Slash { show-hotkey-overlay; }

        Mod+T { spawn "sakura"; }
        Mod+P { spawn "rofi" "-show" "drun"; }
        Mod+Shift+C { close-window; }
        Mod+V { toggle-window-floating; }

        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Up    { focus-window-up; }
        Mod+Down  { focus-window-down; }
        Mod+H     { focus-column-left; }
        Mod+L     { focus-column-right; }
        Mod+K     { focus-window-up; }
        Mod+J     { focus-window-down; }

        Mod+Ctrl+Left  { move-column-left; }
        Mod+Ctrl+Right { move-column-right; }
        Mod+Ctrl+Up    { move-window-up; }
        Mod+Ctrl+Down  { move-window-down; }

        Mod+Page_Down { focus-workspace-down; }
        Mod+Page_Up   { focus-workspace-up; }

        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }

        Mod+Shift+1 { move-column-to-workspace 1; }
        Mod+Shift+2 { move-column-to-workspace 2; }
        Mod+Shift+3 { move-column-to-workspace 3; }
        Mod+Shift+4 { move-column-to-workspace 4; }
        Mod+Shift+5 { move-column-to-workspace 5; }

        Mod+R       { switch-preset-column-width; }
        Mod+F       { maximize-column; }
        Mod+Shift+F { fullscreen-window; }
        Mod+C       { center-column; }
        Mod+Minus   { set-column-width "-10%"; }
        Mod+Equal   { set-column-width "+10%"; }

        Alt+Shift+F4 { spawn "sh" "-c" "flameshot gui"; }

        Print      { screenshot; }

        Ctrl+Print { screenshot-screen; }
        Alt+Print  { screenshot-window; }

        Mod+Shift+E { quit; }
    }
  '';

  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      log-driver = "journald";
    };
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
    allowedBridges = [ "br0" ];
  };

  environment.systemPackages = with pkgs; [
    # Window Management
    gnomeExtensions.appindicator
    gnome-tweaks
    nautilus # implicitly required by vscodium to open file dialogs

    # Wayland/Niri
    rofi
    noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
    xwayland-satellite

    # part of virtualization
    kubectl
    cloud-utils
    kubernetes-helm
    k9s

    # games
    wine
    winetricks

    # Development
    # Scala
    bloop
    clang

    # 3d printing
    prusa-slicer
    # freecad dependency build failure
  ];
}
