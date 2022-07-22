#!/bin/sh

if [ -d /mnt/media/mmcblk0p1 ]; then
  sd=/mnt/media/mmcblk0p1
elif [ -d /mnt/media/mmcblk0 ]; then
  sd=/mnt/media/mmcblk0
fi

[ -x $sd/firmware/init ] && (cd $sd/firmware; ./init)
/gm/config/vg_boot.sh /gm/config
