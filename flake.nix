{
  description = "Main NixOs config";

  inputs = {
    nixpgk.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      ...
    }:
    let
      lib = nixpkgs.lib;
      mkHost =
        hostname: system:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit hostname disko; };
          modules = [
            ./modules/common/packages.nix
            ./hosts/${hostname}/hardware.nix
            ./hosts/${hostname}/host.nix
          ];
        };
    in
    {
      nixosConfigurations = {
        fw12 = mkHost "fw12" "x86_64-linux";
        fw13 = mkHost "fw13" "x86_64-linux";
        vm = mkHost "vm" "x86_64-linux";
      };
    };

}
