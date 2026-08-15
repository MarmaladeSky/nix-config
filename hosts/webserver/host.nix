{
  config,
  modulesPath,
  pkgs,
  site,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "26.05";
  ec2.efi = true;
  boot.loader.grub.configurationLimit = 1;

  environment.systemPackages = [ pkgs.nettools ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "webserver";
  networking.firewall = {
    allowedTCPPorts = [
      80
      443 # webserver
      11010 # easytier
      25
      143
      587 # mail
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

  security.acme = {
    acceptTerms = true;
    defaults.email = "postmaster@junkie.digital";
    certs."mail.junkie.digital" = {
      webroot = "/var/lib/acme/acme-challenge";
      group = "maddy";
      reloadServices = [ "maddy.service" ];
    };
  };

  services.caddy = {
    enable = true;
    email = "{$ACME_EMAIL}";
    environmentFile = config.sops.secrets."caddy-env".path;
    virtualHosts."junkie.digital".extraConfig = ''
      root * ${site}
      encode zstd gzip
      file_server
    '';
    virtualHosts."http://mail.junkie.digital".extraConfig = ''
      root * /var/lib/acme/acme-challenge
      file_server
    '';
  };

  services.maddy = {
    enable = true;
    hostname = "mail.junkie.digital";
    primaryDomain = "junkie.digital";
    tls = {
      loader = "file";
      certificates = [
        {
          certPath = "/var/lib/acme/mail.junkie.digital/fullchain.pem";
          keyPath = "/var/lib/acme/mail.junkie.digital/key.pem";
        }
      ];
    };
    ensureAccounts = [ "david@junkie.digital" ];
  };

  # maddy reads the certificate at startup and exits when it is missing,
  # so it has to wait for ACME and keep retrying until the certificate exists
  systemd.services.maddy = {
    after = [ "acme-mail.junkie.digital.service" ];
    wants = [ "acme-mail.junkie.digital.service" ];
    serviceConfig.RestartSec = "30s";
    unitConfig.StartLimitIntervalSec = 0;
  };
}
