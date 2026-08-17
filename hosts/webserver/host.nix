{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  site,
  ...
}:
let
  outboundDirect = ''
    target.remote outbound_delivery {
      limits {
        destination rate 20 1s
        destination concurrency 10
      }
      mx_auth {
        dane
        mtasts {
          cache fs
          fs_dir mtasts_cache/
        }
        local_policy {
            min_tls_level encrypted
            min_mx_level none
        }
      }
    }
  '';
  outboundSes = ''
    target.smtp outbound_delivery {
      targets tls://email-smtp.us-east-1.amazonaws.com:465
      starttls no
      auth plain {env:SES_SMTP_USER} {env:SES_SMTP_PASSWORD}
    }
  '';
  maddyDefaultConfig = options.services.maddy.config.default;
  maddyConfig = lib.replaceStrings [ outboundDirect ] [ outboundSes ] maddyDefaultConfig;
in
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  assertions = [
    {
      assertion = maddyConfig != maddyDefaultConfig;
      message = "maddy outbound_delivery block no longer matches the nixpkgs default config";
    }
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

  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment.enable = true;
    jails.maddy = {
      filter.Definition = {
        failregex = ''^.*authentication failed.*"src_ip":"\[?<HOST>\]?:[0-9]+".*$'';
        journalmatch = "_SYSTEMD_UNIT=maddy.service";
      };
      settings = {
        backend = "systemd";
        port = "143,587";
        maxretry = 5;
      };
    };
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
    secrets."maddy-env" = {
      sopsFile = ../../secrets/maddy.env;
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
      header Cache-Control "no-cache"
      file_server
    '';
    virtualHosts."http://mail.junkie.digital".extraConfig = ''
      root * /var/lib/acme/acme-challenge
      file_server
    '';
    virtualHosts."openpgpkey.junkie.digital".extraConfig = ''
      handle_path /.well-known/openpgpkey/junkie.digital/* {
        root * ${./wkd}
        header Access-Control-Allow-Origin "*"
        header Content-Type "application/octet-stream"
        file_server
      }
      handle {
        respond 404
      }
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
    config = maddyConfig;
    secrets = [ config.sops.secrets."maddy-env".path ];
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
