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
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = {
    enable = true;
    email = "email@example.com";
    acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    virtualHosts."junkie.digital".extraConfig = ''
      respond "Hello from caddy"
    '';
  };
}
