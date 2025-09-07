{
  description = "Main NixOs config";

  inputs = {
    nixpgk.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      nixos-hardware,
      ...
    }:
    {
      nixosConfigurations = {
        fw12 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit disko;
            hostname = "fw12";
          };
          modules = [
            nixos-hardware.nixosModules.framework-12-13th-gen-intel
            ./modules/common-tui.nix
            ./modules/common-gui.nix
            ./hosts/fw12/hardware.nix
            ./hosts/fw12/host.nix
          ];
        };
        fw13 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit disko;
            hostname = "fw13";
          };
          modules = [
            ./modules/common-tui.nix
            ./modules/common-gui.nix
            ./hosts/fw13/hardware.nix
            ./hosts/fw13/host.nix
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
            ./modules/common-gui.nix
            ./hosts/vm/hardware.nix
            ./hosts/vm/host.nix
          ];
        };
      };
    };

}
