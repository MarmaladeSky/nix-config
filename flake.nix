{
  description = "Main NixOs config";

  inputs = {
    nixpgk.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-mill.url = "github:nixos/nixpkgs/a1bab9e494f5f4939442a57a58d0449a109593fe";
    disko.url = "github:nix-community/disko";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-mill,
      disko,
      nixos-hardware,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        fw12 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            disko = disko;
            hostname = "fw12";
            home-manager = home-manager;
            inherit nixpkgs-mill;
          };
          modules = [
            nixos-hardware.nixosModules.framework-12-13th-gen-intel
            ./modules/common-tui.nix
            ./modules/common-gui.nix
            ./modules/home-manager-tui.nix
            ./modules/home-manager-gui.nix
            ./hosts/fw12/hardware.nix
            ./hosts/fw12/host.nix
          ];
        };
        fw13 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit disko nixpkgs-mill;
            hostname = "fw13";
          };
          modules = [
            ./modules/common-tui.nix
            ./modules/common-gui.nix
            ./hosts/fw13/hardware.nix
            ./hosts/fw13/host.nix
          ];
        };
        pi = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit disko nixpkgs-mill;
            hostname = "raspberry";
          };
          modules = [
            ./modules/common-tui.nix
	    nixos-hardware.nixosModules."raspberry-pi-4"
            ./hosts/pi/hardware.nix
            ./hosts/pi/host.nix
          ];
        };
        vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit disko nixpkgs-mill;
            hostname = "vm";
          };
          modules = [
            ./modules/common-tui.nix
            ./modules/common-gui.nix
            ./modules/home-manager-tui.nix
            ./hosts/vm/hardware.nix
            ./hosts/vm/host.nix
          ];
        };
      };
    };

}
