#!/bin/bash

source "$(dirname "$(command -v "$0")")/type_in.sh"

qemu_drive_template() {
  file="$1"
  serial="$2"
  bootindex="$3"

  option="-drive file=$file"
  option="$option,id=drive_$serial"
  option="$option,if=none"
  option="$option,format=raw"
  option="$option,media=disk"

  option="$option -device ahci,id=ahci_$serial"
  option="$option -device scsi-hd,drive=drive_$serial"
  option="$option,serial=device_$serial"
  option="$option,bus=ahci_$serial.0"
  option="$option,bootindex=$bootindex"

  echo "$option"
}

QEMU_MONITOR_IP=127.0.0.1
QEMU_MONITOR_PORT="$RANDOM"
SCENARIO="$1"
DISK="${2:--}"
OUTPUT_FILE="${3:-output.log}"
MEMORY="${4:-1024}"
shift 4
QEMU_OPTIONS_APPEND="$@"
set_qemu_monitor $QEMU_MONITOR_IP:$QEMU_MONITOR_PORT

QEMU_DEFAULT_OPTIONS="-m $MEMORY"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -enable-kvm"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -smp $(nproc)"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -monitor tcp:$QEMU_MONITOR_IP:$QEMU_MONITOR_PORT,server,nowait"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -netdev user,id=ssh_net,hostfwd=tcp:127.0.0.1:12222-:22"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -device e1000,netdev=ssh_net"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -chardev file,id=serial_port,path=$OUTPUT_FILE"
QEMU_DEFAULT_OPTIONS="$QEMU_DEFAULT_OPTIONS -device pci-serial,chardev=serial_port"

if [ "$DISK" != '-' ]
then
  TARGET_DISK_OPTS="$(qemu_drive_template "$TARGET_DISK" "$TARGET_DISK_$RANDOM" 1)"
fi

QEMU_OPTIONS="$QEMU_DEFAULT_OPTIONS $TARGET_DISK_OPTS $QEMU_OPTIONS_APPEND"
QEMU_OPTIONS="$(echo "$QEMU_OPTIONS" | tr '\n' ' ')"

qemu-system-x86_64 $QEMU_OPTIONS &

source "$SCENARIO"

wait $(jobs -p)
