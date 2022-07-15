#!/bin/sh -l

##################################################################################
## purpose: Initialize the Chuangmi 720P hack                                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################
(
/mnt/data/imi/imi_init/S01logging $([ "${ENABLE_LOGGING:-0}" -eq 1 ] && echo restart || echo stop)
echo 0 > /tmp/ft_mode

mkdir -p /tmp/restartd
touch /tmp/restartd/restartd
cp /mnt/data/restartd/restartd.conf /tmp/restartd
mount --bind /mnt/data/restartd/restartd /tmp/restartd/restartd
mount --rbind /tmp/restartd /mnt/data/restartd
sed -i 's~^miio_client .*~miio_client "/mnt/data/ot_wifi_tool/miio_client -D" "/mnt/data/imi/imi_init/S93miio_client start" "/bin/echo '\''miio_client is running'\''"~' /mnt/data/restartd/restartd.conf
echo "restartd \"/mnt/data/restartd/restartd\" \"/mnt/data/imi/imi_init/S99restartd restart\" \"/bin/echo 'restartd is running'\"" >> /mnt/data/restartd/restartd.conf

HOSTNAME=${HOSTNAME:-$(nvram factory get mac | tr [:upper:] [:lower:] | tr -d :)}
echo "Setting hostname to '$HOSTNAME'."
hostname $HOSTNAME
echo $HOSTNAME >/etc/hostname
echo "127.0.0.1 localhost $HOSTNAME" >/etc/hosts

if [ -n "$WIFI_SSID" ]; then
  echo "Configuring WiFi to '$WIFI_SSID'."
  wifi "$WIFI_SSID" "$WIFI_PASSWORD"
fi

if [ -n "$PASSWORD" ]; then
  echo "Setting root password."
  echo "root:$PASSWORD" | chpasswd
fi

if [ -n "$TZ" ]; then
  echo "Setting timezone to '$TZ'."
  [ -f /usr/share/zoneinfo/uclibc/$TZ ] && cp -f /usr/share/zoneinfo/uclibc/$TZ /etc/localtime
  rm /etc/TZ
  echo $TZ >/etc/TZ
fi

[ "${ENABLE_CLOUD:-0}" -eq 0 ] && cloud --disable
ota $([ "${ENABLE_OTA:-0}" -eq 1 ] && echo --enable || echo --disable)

##################################################################################
## Start enabled Services                                                       ##
##################################################################################

if ! [ -f /mnt/data/test/boot.sh ]
then
    ln -s -f $SD/firmware/scripts/.boot.sh /mnt/data/test/boot.sh
fi

) | logger -t firmware
