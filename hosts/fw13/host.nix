{
  config,
  pkgs,
  lib,
  ...
}:

let
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    exec "$@"
  '';

  intelGraphicsPackages = with pkgs; [
    intel-media-driver
    libva-vdpau-driver
    intel-compute-runtime
    vpl-gpu-rt
  ];
in
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  boot.loader.efi.canTouchEfiVariables = true;
  # default: eGPU connected (nvidia). See nvidia-egpu-disconnected specialisation.
  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [ "video=eDP-1:d" ];

  # Canon as webcam
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback.out ];
  boot.kernelModules = [
    "v4l2loopback"
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback exclusive_caps=1 card_label="Virtual Camera"
    options nvidia NVreg_EnableGpuFirmware=0
  '';

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    forceFullCompositionPipeline = true;

    prime = {
      offload.enable = false;
      reverseSync.enable = false;
      sync.enable = false;
    };
  };

  networking = {
    hostName = "fw13";
    firewall = {
      enable = true;
      allowedUDPPorts = [ 5353 ];
      allowedTCPPorts = [
        2283
        8000
        9001
        631
      ];
    };
    useNetworkd = false;
    useHostResolvConf = false;
    resolvconf.enable = true;
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."easytier-env" = {
      sopsFile = ../../secrets/easytier.env;
      format = "dotenv";
      owner = "root";
    };
  };

  # DNS
  services.resolved.enable = false;

  services.easytier = {
    enable = true;
    instances.default = {
      settings = {
        hostname = "fw13";
        ipv4 = "10.1.1.3/24";
      };
      environmentFiles = [
        config.sops.secrets."easytier-env".path
      ];
    };
  };

  # Docker
  virtualisation.docker = {
    enable = true;
    extraOptions = "--default-ulimit nofile=65535:65535";
    rootless = {
      enable = true;
    };
    daemon.settings = {
      data-root = "/home/docker-data";
    };
  };
  hardware.nvidia-container-toolkit.enable = false;

  security.wrappers = {
    docker-rootlesskit = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_bind_service+ep";
      source = "${pkgs.rootlesskit}/bin/rootlesskit";
    };
  };

  # Required to run different architectures by qemu
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "riscv64-linux"
  ];

  virtualisation.libvirtd = {
    enable = true;
    allowedBridges = [
      "virbr0"
      "br0"
    ];
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  systemd.services.virt-secret-init-encryption.enable = false;

  # IOS (usbmuxd itself is enabled by common-tui; fw13 just pins usbmuxd2)
  services.usbmuxd.package = pkgs.usbmuxd2;

  xdg.portal = {
    enable = true;

    # Portal backend(s) available on the system
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-xapp
    ];

    # Backend selection (portals.conf semantics)
    config.common.default = [
      "xapp"
      "gtk"
    ];
  };

  # Flatpack
  services.flatpak.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

  services.pulseaudio = {
    enable = false;
    support32Bit = true;
  };

  # Thunderbolt service
  services.hardware.bolt.enable = true;

  # Mouse
  services.libinput.mouse.accelSpeed = "0.6";
  services.libinput.mouse.transformationMatrix = "1.6 0 0 0 1.6 0 0 0 1";

  # Wacom
  hardware.opentabletdriver.enable = true;
  hardware.opentabletdriver.daemon.enable = true;

  # SSH (openssh is enabled by common-tui; fw13 adds host-specific settings)
  services.openssh = {
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # fingerprint
  services.fprintd.enable = true;

  # Locale
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Hardware accelaration
  nixpkgs.config.packageOverrides = pkgs: {
    intel-vaapi-driver = pkgs.intel-vaapi-driver.override { enableHybridCodec = true; };
  };
  hardware.graphics = {
    enable = true;
    extraPackages = intelGraphicsPackages;
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  # Framework specific
  services.fwupd.enable = true;

  # i3lock: security.pam.services.i3lock comes from home-manager-gui.nix.
  # fw13 additionally provides i3lock-color.
  security.pam.services.i3lock-color = {
    enable = true;
    text = ''
      auth include login
      account include login
      password include login
      session include login
    '';
  };

  # Configure keymap in X11
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ]; # default: eGPU connected

      defaultDepth = 24;
      config = ''
        Section "ServerLayout"
          Identifier "layout"
          Screen 0 "screen0"
          Option "AllowExternalGpus" "True"
        EndSection

        Section "Extensions"
          Option "Composite" "Enable"
        EndSection

        Section "Device"
          Identifier "eGPU"
          Driver "nvidia"
          BusID "PCI:129@0:0:0"
          Option "AllowEmptyInitialConfiguration" "True"
          Option "AllowExternalGpus" "True"
          Option "AddARGBGLXVisuals" "True"
        EndSection

        Section "Screen"
          Identifier "screen0"
          Device "eGPU"
          DefaultDepth 24
        EndSection
      '';

      dpi = 180;
      xkb = {
        layout = "us,ru";
        variant = "";
        options = "grp:caps_toggle";
      };
      enable = true;
      windowManager.awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks
          luadbi-mysql
        ];
      };
      displayManager = {
        lightdm = {
          enable = true;
          greeter.enable = true;
        };
      };
    };
    picom.enable = true;
    displayManager.defaultSession = "none+awesome";
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    i2p = {
      enable = true;
    };

  };

  specialisation."nvidia-egpu-disconnected".configuration = {
    boot.blacklistedKernelModules = lib.mkForce [
      "nouveau"
      "nvidia"
      "nvidiafb"
      "nvidia-drm"
      "nvidia-uvm"
      "nvidia-modeset"
    ];

    # Undo the base config's eGPU-specific settings so the laptop runs on its
    # internal display + Intel iGPU. Drop "video=eDP-1:d" (base) but keep the
    # Framework module's "nvme.noacpi=1" power param.
    boot.kernelParams = lib.mkForce [ "nvme.noacpi=1" ];
    services.xserver.config = lib.mkForce "";

    hardware.nvidia-container-toolkit.enable = lib.mkForce false;

    hardware.graphics.extraPackages = lib.mkForce intelGraphicsPackages;

    services.xserver.videoDrivers = lib.mkForce [
      "modesetting"
      "fbdev"
    ];
  };

  # User
  users.users.user = {
    isNormalUser = true;
    description = "user";
    extraGroups = [
      "networkmanager"
      "wheel"
      "audio"
      "video"
      "docker"
      "libvirtd"
      "dialout"
    ];
    packages = with pkgs; [ ];
  };

  users.users.sandbox = {
    isNormalUser = true;
    home = "/home/sandbox";
    createHome = true;
    extraGroups = [
      "audio"
      "video"
    ];
  };

  # syncthing
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    configDir = "/home/user/.config/syncthing";
    user = "user";
    group = "users";
    settings = {
      devices =
        let
          ids =
            if builtins.pathExists ../../syncthing-devices.nix then
              import ../../syncthing-devices.nix
            else
              {
                fw12 = "AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA-AAAAAAA";
                fw13 = "BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN-BBBBBBB-BBBBBBN";
                thinkpad = "CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2-CCCCCCC-CCCCCC2";
                pi = "DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH-DDDDDDD-DDDDDDH";
              };
        in
        {
          fw12.id = ids.fw12;
          fw13.id = ids.fw13;
          thinkpad.id = ids.thinkpad;
          pi.id = ids.pi;
        };

      folders = {
        "Pictures" = {
          path = "/home/user/Pictures";
          ignorePerms = false;
          devices = [
            "fw12"
            "thinkpad"
            "pi"
          ];
        };
        "Documents" = {
          path = "/home/user/Documents";
          ignorePerms = false;
          devices = [
            "fw12"
            "thinkpad"
            "pi"
          ];
        };
        "Videos" = {
          path = "/home/user/Videos";
          ignorePerms = false;
          devices = [
            "fw12"
            "thinkpad"
            "pi"
          ];
        };
        "Music" = {
          path = "/home/user/Music";
          ignorePerms = false;
          devices = [
            "fw12"
            "thinkpad"
            "pi"
          ];
        };
      };
    };
  };

  # precompiled (nix-ld is enabled by common-tui; fw13 adds extra libraries)
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "intel-media-sdk-23.2.2"
    "libsoup-2.74.3"
  ];

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.steam.gamescopeSession.enable = true; # Integrates with programs.steam

  # fw13 needs the vulkan (--use-angle) Brave build. Override pkgs.brave via an
  # overlay so common-gui's `brave` resolves to this customized version
  nixpkgs.overlays = [
    (final: prev: {
      brave =
        let
          braveVk = prev.brave.override {
            commandLineArgs = [
              "--use-angle=vulkan"
              "--enable-features=Vulkan"
            ];
          };
        in
        prev.symlinkJoin {
          name = "brave";
          paths = [ braveVk ];
          nativeBuildInputs = [ prev.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/brave \
              --set-default VK_ICD_FILENAMES "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.json:/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json"

            # Desktop entries point at the inner binary (no env wrapper); redirect them.
            for d in $out/share/applications/*.desktop; do
              src=$(readlink -f "$d")
              rm "$d"
              sed "s,${braveVk}/bin/brave,$out/bin/brave,g" "$src" > "$d"
            done
          '';
        };
    })
  ];

  environment.systemPackages = with pkgs; [
    # Editors
    vim
    emacs

    # tools
    parallel
    chromium
    imagemagick
    libwebp
    xournalpp
    pdfcpu
    screenfetch
    dnsmasq
    i3lock
    i3lock-color
    linuxKernel.packages.linux_zen.cpupower

    # email
    aerc
    neomutt
    alpine
    himalaya

    pulseaudio
    pavucontrol
    pamixer
    dconf
    easyeffects
    krita
    # freecad dependency build failure
    mangohud
    networkmanagerapplet
    networkmanager-openvpn
    openvpn
    alacarte
    jdk
    openjdk11
    libva-utils
    zoom-us
    webcamoid
    acpilight
    arandr
    tree
    discord
    k9s
    kubernetes-helm
    jetbrains.idea-oss
    jetbrains.webstorm
    jetbrains.phpstorm
    postman
    direnv
    code-cursor
    android-studio
    websocat
    rlwrap
    bundletool
    unrar
    xarchiver
    clipmenu
    postgresql
    gradle
    pv
    powertop
    yt-dlp
    prusa-slicer
    blender
    nil
    fw-ectool
    dmidecode
    lshw
    mesa-demos
    bubblewrap
    xinit
    nvidia-offload
    libnvidia-container
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    conda
    nmap
    net-tools
    dig

    # Finance
    # bitcoin
    (bitcoin.override {
      sqlite = sqlite.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ zlib ];
      });
    })

    # Web
    mdbook
    zola

    # Work
    circleci-cli
    terraform
    yarn
    gcc

    # neovim
    ripgrep

    # Virtualization
    qemu
    (pkgs.writeShellScriptBin "qemu-system-x86_64-uefi" ''
      qemu-system-x86_64 \
        -bios ${pkgs.OVMF.fd}/FV/OVMF.fd \
        "$@"
    '')
    cloud-init
    cloud-utils
    k3s

    # Scala
    coursier
    bloop
    clang

    # Canon as webcam
    gphoto2
    (ffmpeg.override {
      withXcb = true;
    })
    mediainfo

    # Wine related
    wineWow64Packages.staging
    wineWow64Packages.waylandFull
    winetricks

    openssl

    # Image view
    feh
    sxiv

    bc
  ];

  # Scale UI
  environment.variables = {
    GDK_SCALE = "1";
    STEAM_FORCE_DESKTOPUI_SCALING = "2";
  };

  systemd.user.services.pipewire-pulse.path = [ pkgs.pulseaudio ];

  # Java
  programs.java.enable = true;

  # Shell (fish is enabled by common-tui; fw13 adds aliases)
  programs.fish.shellAliases = {
    fehs = "feh --scale-down --auto-zoom --no-xinerama -g +0+0 --start-at";
  };

  # File manager
  programs.xfconf.enable = true;
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}
