{ config, modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "26.05";
  ec2.efi = true;

  environment.systemPackages = [ pkgs.nettools ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "webserver";
  networking.firewall = {
    allowedTCPPorts = [
      80 443 # webserver
      11010 # easytier
    ];
    allowedUDPPorts = [ 11010 ]; # easytier
  };

  # easytier service
  services.easytier = {
    enable = true;
    instances.default = {
      settings.ipv4 = "10.1.1.1/24";
      environmentFiles = [ config.sops.secrets."easytier-env".path ];
    };
  };

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."caddy-env" = {
      sopsFile = ../../secrets/caddy.env;
      format = "dotenv";
      owner = "caddy";
    };
    secrets."easytier-env" = {
      sopsFile = ../../secrets/easytier.env;
      format = "dotenv";
      owner = "root";
    };
  };

  services.caddy = {
    enable = true;
    email = "{$ACME_EMAIL}";
    environmentFile = config.sops.secrets."caddy-env".path;
    virtualHosts."junkie.digital".extraConfig = ''
      respond "Hello from caddy"
    '';
  };
}
