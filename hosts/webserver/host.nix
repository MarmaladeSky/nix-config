{ modulesPath, pkgs, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/amazon-image.nix"
  ];

  system.stateVersion = "25.11";
  ec2.efi = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  networking.hostName = "webserver";
  networking.firewall.allowedTCPPorts = [ 8080 ];

  services.darkhttpd = {
    enable = true;
    port = 8080;
    address = "::";
    rootDir = pkgs.writeTextDir "index.html" ''
      <!doctype html>
      <html>
        <head><title>webserver</title></head>
        <body><h1>Hello from darkhttpd</h1></body>
      </html>
    '';
  };
}
