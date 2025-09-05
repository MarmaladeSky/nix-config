{
  ...
}:
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/virtio-vmroot";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "512M";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
              extraArgs = [ "-nboot" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              extraArgs = [ "-Lroot" ];
            };
          };
        };
      };
    };
  };
}
