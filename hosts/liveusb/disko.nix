let
  mountOptions = subvol: [
    "subvol=${subvol}"
    "compress=zstd"
    "noatime"
  ];
in
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/usb-Kingston_DT_HyperX_3.0_20CF30E11675BF80B2063A4E-0:0";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
        };
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptusb";
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "liveusb"
                "-f"
              ];
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = mountOptions "root";
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = mountOptions "home";
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = mountOptions "nix";
                };
                "/log" = {
                  mountpoint = "/var/log";
                  mountOptions = mountOptions "log";
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems."/var/log".neededForBoot = true;
}
