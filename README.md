# NixOS multidevice configuration [Work In Progress]

An example of management of the multiple devices via Nix Flake.

This includes:
- filesystem management via [disko](https://github.com/nix-community/disko)
- simple (but not automated) installation
- common module for the shared configuration
- host modules for the host-specific configuration

## VM Installation Steps

### Run Live ISO
[qemu-system-x86_64-uefi](https://nixos.wiki/wiki/QEMU) in run.sh is just a way to provide OVMF in a NixOS host.  
You'll need QEMU with UEFI.
```sh
./run.sh /path/to/NixOS/livecd.iso
```

### Mount flake code
```sh
mkdir /9p
mount -t 9p -o trans=virtio,version=9p2000.L host0 /9p
```

### Installation
```sh
# Format and mount filesystems
nix run \
  --extra-experimental-features "flakes nix-command" \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --arg disk '"/dev/disk/by-id/virtio-vmroot"' \
  --yes-wipe-all-disks /9p/hosts/vm/disko.nix

# Copy flake source
mkdir -p /mnt/etc/nixos
cp -r /9p/.git /mnt/etc/nixos/
git -C /mnt/etc/nixos reset --hard HEAD

# Generate hardware config
nixos-generate-config --no-filesystems --show-hardware-config > /mnt/etc/nixos/hosts/vm/hardware.nix

# Install NixOS
# Explicitly set type of flake as path because we have hardware.nix that is not part of the repository
nixos-install --flake path:/mnt/etc/nixos#vm
```

## Changes and updates workflow
As a result of the installation we should have flake repo in `/etc/nixos` with the git ignored generated `hardware.nix`.

Git doesn't like to work under root, so this step is required
```sh
git config --global --add safe.directory /etc/nixos
```

To make changes and/or updates 
```sh
# make some changes or git pull for them

# test the configuration and make it the default boot option
nixos-rebuild test --flake path:/etc/nixos#vm
nixos-rebuild boot --flake path:/etc/nixos#vm
# or just switch
nixos-rebuild switch --flake path:/etc/nixos#vm
# or update
nixos-rebuild switch --upgrade --flake path:/etc/nixos#vm

# commit the change and push it
git add .
git commit -m "Here some new changes"
git push
```

## Bonuses

- [The derivation](./pkgs/revelation/default.nix) of [Revelation password manager](https://github.com/mikelolasagasti/revelation)