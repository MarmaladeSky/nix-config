{
  config,
  pkgs,
  disko,
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
  # Super I/O chip (NCT6779D) that exposes the fan headers; not autoloaded
  # since it's an ISA-bus chip with no PnP ID for udev to match against.
  boot.kernelModules = [ "nct6775" ];

  time.timeZone = "UTC";
  networking.hostName = "huananzhi";

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."easytier-env" = {
      sopsFile = ../../secrets/easytier.env;
      format = "dotenv";
      owner = "root";
    };
  };

  users.users.user = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "dialout"
      "libvirtd"
    ];
  };

  services = {
    easytier = {
      enable = true;
      instances.default = {
        settings = {
          hostname = "huananzhi";
          ipv4 = "10.1.1.4/24";
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
        devices =
          let
            ids = {
              fw12 = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA";
              fw13 = "BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN";
              thinkpad = "CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2";
              pi = "DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH";
              huananzhi = "EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE-EEEEEEE";
            }
            // (
              if builtins.pathExists ../../syncthing-devices.nix then import ../../syncthing-devices.nix else { }
            );
          in
          {
            fw12.id = ids.fw12;
            fw13.id = ids.fw13;
            thinkpad.id = ids.thinkpad;
            pi.id = ids.pi;
            huananzhi.id = ids.huananzhi;
          };

        folders = {
          "Pictures" = {
            path = "/home/user/Pictures";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Documents" = {
            path = "/home/user/Documents";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Videos" = {
            path = "/home/user/Videos";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
          "Music" = {
            path = "/home/user/Music";
            ignorePerms = false;
            devices = [
              "fw12"
              "fw13"
              "thinkpad"
              "pi"
            ];
          };
        };
      };
    };

    xserver = {
      enable = true;
      displayManager.lightdm.enable = true;
      windowManager.awesome.enable = true;
      xkb.layout = "us,ru";
      xkb.variant = ",";
      xkb.options = "grp:caps_toggle";
      videoDrivers = [ "nvidia" ];
    };
    displayManager.defaultSession = "none+awesome";
    picom.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    gvfs.enable = true;
    udisks2.enable = true;
  };

  hardware.graphics.enable = true;
  hardware.nvidia = {
    # Pascal (GTX 1070, and the Tesla P40 to come) was dropped from the mainline
    # driver branch; the 580.xx legacy branch is the last one that supports it.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    # Pascal predates open-kernel-module support.
    open = false;
    modesetting.enable = true;
    # Keep the headless Tesla P40 initialized for compute once it's installed.
    nvidiaPersistenced = true;
  };
  hardware.nvidia-container-toolkit.enable = true;

  # Tesla P40 has no fan of its own; this drives the header confirmed by hand
  # to control its external blower (NCT6779D's pwm2) off the P40's own temp.
  # Fails safe to full speed whenever the temp can't be read or the service stops.
  systemd.services.tesla-p40-fan = {
    description = "Tesla P40 fan control";
    wantedBy = [ "multi-user.target" ];
    after = [ "multi-user.target" ];
    path = [
      config.hardware.nvidia.package.bin
      pkgs.gawk
      pkgs.gnugrep
    ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = "5s";
      ExecStopPost = pkgs.writeShellScript "tesla-p40-fan-failsafe" ''
        hwmon=$(grep -l nct6779 /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1 | xargs -r dirname)
        [ -n "$hwmon" ] && echo 255 > "$hwmon/pwm2"
      '';
    };
    script = ''
      set -u

      hwmon=""
      while [ -z "$hwmon" ]; do
        hwmon=$(grep -l nct6779 /sys/class/hwmon/hwmon*/name 2>/dev/null | head -1 | xargs -r dirname)
        [ -z "$hwmon" ] && sleep 5
      done
      echo 1 > "$hwmon/pwm2_enable"

      while true; do
        temp=$(nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader,nounits 2>/dev/null \
          | awk -F, '$1 ~ /Tesla P40/ { gsub(/^ +/, "", $2); print $2; exit }')

        if [ -z "$temp" ]; then
          echo "tesla-p40-fan: could not read P40 temperature, forcing full speed" >&2
          echo 255 > "$hwmon/pwm2"
        else
          # 100 is the lowest speed confirmed audible/working by hand; ramps
          # linearly to full speed by 80C, well under the P40's throttle point.
          awk -v t="$temp" '
            BEGIN {
              if (t <= 45) pwm = 100;
              else if (t <= 80) pwm = 100 + (t - 45) * (255 - 100) / (80 - 45);
              else pwm = 255;
              print int(pwm);
            }' > "$hwmon/pwm2"
        fi
        sleep 5
      done
    '';
  };

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = [ "gtk" ];
  };

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
    nautilus
    pavucontrol
    pamixer
    arandr
    feh
    zoom-us
    kubectl
    cloud-utils
    kubernetes-helm
    k9s
  ];
}
