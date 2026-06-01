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
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets."caddy-env" = {
      sopsFile = ../../secrets/caddy-env;
      format = "binary";
      owner = "caddy";
    };
  };

  services.caddy = {
    enable = true;
    email = "{$ACME_EMAIL}";
    environmentFile = config.sops.secrets."caddy-env".path;
    acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    virtualHosts."junkie.digital".extraConfig = ''
      respond "Hello from caddy"
    '';
  };
}
