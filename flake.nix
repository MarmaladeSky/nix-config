{
  description = "Main NixOs config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
    noctalia-shell.url = "github:noctalia-dev/noctalia-shell";
    noctalia-shell.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    site.url = "git+ssh://git@github.junkie.digital/MarmaladeSky/junkie-site";
    site.inputs.nixpkgs.follows = "nixpkgs";
    elkfarm.url = "git+ssh://git@github.com/MarmaladeSky/elkfarm";
    elkfarm.inputs.nixpkgs.follows = "nixpkgs";
    hadaka-agent.url = "github:MarmaladeSky/hadaka-agent";
    hadaka-agent.inputs.nixpkgs.follows = "nixpkgs";
    nix-apple-dev.url = "github:m9tdev/nix-apple-dev";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      nixos-hardware,
      home-manager,
      noctalia-shell,
      sops-nix,
      site,
      elkfarm,
      hadaka-agent,
      nix-apple-dev,
      ...
    }:
    let
      desktopArgs = hostname: {
        inherit disko home-manager hostname;
        elkfarm = elkfarm.packages.x86_64-linux.default;
        hadaka-agent = hadaka-agent.packages.x86_64-linux.default;
      };
      desktopModules = [
        sops-nix.nixosModules.sops
        ./modules/common-tui.nix
        ./modules/common-gui.nix
        ./modules/home-manager-tui.nix
        ./modules/home-manager-gui.nix
      ];
    in
    {
      nixosConfigurations = {
        fw12 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = desktopArgs "fw12" // {
            inherit noctalia-shell nix-apple-dev;
          };
          modules = desktopModules ++ [
            nixos-hardware.nixosModules.framework-12-13th-gen-intel
            nix-apple-dev.nixosModules.default
            ./hosts/fw12/hardware.nix
            ./hosts/fw12/host.nix
          ];
        };
        fw13 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = desktopArgs "fw13";
          modules = desktopModules ++ [
            nixos-hardware.nixosModules.framework-intel-core-ultra-series1
            ./hosts/fw13/hardware.nix
            ./hosts/fw13/host.nix
          ];
        };
        huananzhi = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = desktopArgs "huananzhi";
          modules = desktopModules ++ [
            ./hosts/huananzhi/hardware.nix
            ./hosts/huananzhi/host.nix
          ];
        };
        thinkpad = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = desktopArgs "thinkpad";
          modules = desktopModules ++ [
            ./hosts/thinkpad/hardware.nix
            ./hosts/thinkpad/host.nix
          ];
        };
        liveusb = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = desktopArgs "liveusb";
          modules = desktopModules ++ [
            ./hosts/liveusb/host.nix
          ];
        };
        pi = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit disko;
            hostname = "raspberry";
          };
          modules = [
            sops-nix.nixosModules.sops
            ./modules/common-tui.nix
            nixos-hardware.nixosModules."raspberry-pi-4"
            ./hosts/pi/hardware.nix
            ./hosts/pi/host.nix
          ];
        };
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit disko;
            hostname = "vm";
          };
          modules = [
            ./modules/common-tui.nix
            ./modules/home-manager-tui.nix
            ./hosts/vm/hardware.nix
            ./hosts/vm/host.nix
          ];
        };
        webserver = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            site = site.packages.aarch64-linux.default;
            hostname = "webserver";
          };
          modules = [
            sops-nix.nixosModules.sops
            ./hosts/webserver/host.nix
          ];
        };
      };
    };

}
