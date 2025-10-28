# NixOS multidevice configuration [Work In Progress]

An example of management of the multiple devices via Nix Flake.

This includes:

- filesystem management via [disko](https://github.com/nix-community/disko)
- simple (but not automated) installation
- common modules for the shared configuration
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

## Raspberry Pi 4B Installation

Have Raspberry Pi firmware updates with USB Boot support.

Burn nixos sd image to a USB drive with caligula (`nix-shell -p caligula`):

```sh
nix-shell -p caligula
caligula burn nixos-image-sd-card-*-aarch64-linux.img.zst
```

Boot from USB, set password to nixos user with passwd, connect with ssh using this user.

Move this configuration to the host (for example with sshfs, rsync, etc.).

Prepare partitions layout with Disko:

```sh
nix run \
  --extra-experimental-features "flakes nix-command" \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  --yes-wipe-all-disks ./hosts/pi/disko.nix
```

Copy this configuration to /etc/nixos:

```sh
mkdir -p /mnt/etc/nixos
cp -r ./.git /mnt/etc/nixos/
git -C /mnt/etc/nixos reset --hard HEAD
```

Generate hardware configuration and install nixos:

```sh
nixos-generate-config --no-filesystems --show-hardware-config > /mnt/etc/nixos/hosts/pi/hardware.nix
nixos-install --flake path:/mnt/etc/nixos#pi
```

Install firmware from the NixOS image (there is no cleaner way):

```sh
cp -r /boot/* /mnt/boot/
```

Unfortunately, [there is no cleaner way](https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi#Notes_about_the_boot_process) and official documentation suggests to do some mental gymnastics:

> This configuration is the most similar to the way that NixOS works on other devices. The downside is that NixOS won't attempt to manage anything associated with the first and second stage bootloaders (e.g. config.txt).  
> You can feel better about this by thinking about this configuration as similar to BIOS settings.

## Changes and updates workflow

As a result of the installation we should have flake repo in `/etc/nixos` with the generated and gitignored `hardware.nix`.

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
nix flake update --flake path:/etc/nixos
nixos-rebuild switch --flake path:/etc/nixos#vm

# commit the change and push it
git add .
git commit -m "Here some new changes"
git push

# clean up all old generations
nix-collect-garbage --delete-old
nixos-rebuild switch --flake path:/etc/nixos#vm
```

## Bonuses

- [The derivation](./pkgs/revelation/default.nix) of [Revelation password manager](https://github.com/mikelolasagasti/revelation)
