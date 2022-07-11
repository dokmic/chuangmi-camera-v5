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

if [ -n "$WIFI_SSID" ]; then
  echo "Configuring WiFi to '$WIFI_SSID'."
  wifi "$WIFI_SSID" "$WIFI_PASSWORD"
fi

if [ -n "$PASSWORD" ]; then
  echo "Setting root password."
  echo "root:$PASSWORD" | chpasswd
fi

##################################################################################
## Set time zone                                                                ##
##################################################################################

if [ -n "${TIMEZONE}" ]
then
    echo "Setting timezone to '$TIMEZONE'."

    if [ -f "/usr/share/zoneinfo/uclibc/$TIMEZONE" ]
    then
        cp -f /usr/share/zoneinfo/uclibc/$TIMEZONE /etc/localtime
    fi

    rm /tmp/etc/TZ
    echo "${TIMEZONE}" > /tmp/etc/TZ
    export TZ="${TIMEZONE}"
fi

##################################################################################
## Set hostname and format /etc/hosts                                           ##
##################################################################################

if [ -n "${CAMERA_HOSTNAME}" ]
then
    echo "Setting hostname to '$CAMERA_HOSTNAME'."
    echo "${CAMERA_HOSTNAME}" > /etc/hostname
    hostname "${CAMERA_HOSTNAME}"

    echo -e "127.0.0.1 \tlocalhost\n127.0.1.1 \t$CAMERA_HOSTNAME\n\n" > /etc/hosts

    if [ -f "$SD/firmware/etc/hosts" ]
    then
        cat $SD/firmware/etc/hosts >> /etc/hosts
    fi
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
