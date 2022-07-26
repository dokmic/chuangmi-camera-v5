#!/bin/sh

if [ -d /mnt/media/mmcblk0p1 ]; then
  sd=/mnt/media/mmcblk0p1
elif [ -d /mnt/media/mmcblk0 ]; then
  sd=/mnt/media/mmcblk0
fi

tar -xzf $sd/firmware.bin -C /tmp && (cd /tmp/firmware; ./init)
echo 0 >/tmp/ft_mode
