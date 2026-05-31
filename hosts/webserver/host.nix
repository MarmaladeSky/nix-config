{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "26.05";
  ec2.efi = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "webserver";
  networking.firewall.allowedTCPPorts = [ 8080 ];

  services.caddy = {
    enable = true;
    virtualHosts.":8080".extraConfig = ''
      respond "Hello from caddy"
    '';
  };
}
