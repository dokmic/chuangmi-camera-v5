#!/bin/sh

alias vg_boot="/gm/config/vg_boot.sh /gm/config"

if [ -b /dev/mmcblk0p1 ]; then
  DEV=/dev/mmcblk0p1
elif [ -b /dev/mmcblk0 ]; then
  DEV=/dev/mmcblk0
fi

if [ -z "$DEV" ]; then
  echo "Failed to find an SD card volume."
  vg_boot

  exit
fi

export SD=/tmp/sd

mkdir -p $SD
if ! mount -t vfat $DEV $SD; then
  echo "Failed to mount the SD card."
  vg_boot

  exit
fi

cp -r /etc /tmp/
mount --rbind /tmp/etc /etc
echo "export SD=$SD" > /etc/profile.d/00_sd.sh
cp -r $SD/firmware/etc/* /etc

$SD/firmware/init

vg_boot
