#!/bin/sh
# To have the flake working the VM
# - should be lauched with UEFI
# - disk id should '/dev/disk/by-id/virtio-vmroot'
# - current directory should be the root of the flake repo (pwd)
qemu-system-x86_64-uefi -enable-kvm \
  -m 10000 \
  -smp 4 \
  -cdrom $1 \
  -boot order=dc \
  -drive file=nixos-test.img,if=none,format=qcow2,id=drv0 \
  -device virtio-blk-pci,drive=drv0,serial=vmroot \
  -nic user,model=virtio \
  -virtfs local,path=$(pwd),mount_tag=host0,security_model=mapped,id=host0 \
  -display sdl
