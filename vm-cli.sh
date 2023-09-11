#!/usr/bin/env bash

pwd="$(realpath "$(dirname "$0")")"

# shellcheck source=/dev/null
source "$pwd/linux/jiasuqi.conf"

# shellcheck disable=SC2140
sudo -E qemu-system-x86_64 -enable-kvm -daemonize \
    -cpu host \
    -smp 2,sockets=1,cores=2,threads=1 \
    -drive file="$pwd/vm/windows.img",if=virtio \
    -net nic,model=virtio \
    -net tap,ifname="$INTERFACE",script="$pwd/linux/vm-up.sh",downscript="$pwd/linux/vm-down.sh" \
    -m 2G \
    -vga qxl \
    -spice addr=127.0.0.1,port="$SPICE_PORT",disable-ticketing=on \
    -machine usb=on \
    -device usb-tablet \
    -device virtio-serial \
    -chardev spicevmc,id=vdagent,name=vdagent \
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0 \
    "$@"

exec gtk3-nocsd remote-viewer --title Windows spice://127.0.0.1:"$SPICE_PORT" 2> /dev/null
