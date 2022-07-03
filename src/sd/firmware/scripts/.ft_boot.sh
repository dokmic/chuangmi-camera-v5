#!/bin/sh -l

##################################################################################
## purpose: Initialize the Chuangmi 720P hack                                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################

LOGDIR=$SD/log
LOGFILE=$LOGDIR/ft_boot.log
mkdir -p $LOGDIR

## Bail out if disabled in configuration
if [ "${DISABLE_HACK}" -eq 1 ]
then
    echo "Hack disabled in config.cfg, starting normal boot sequence" | tee -a "${LOGFILE}"
    echo 0 > /tmp/ft_mode
    vg_boot
    exit
fi

(
cat << EOF
################################
## Running Chuangmi 720P hack ##
################################

Chuangmi 720P configuration:

  HOSTNAME       = ${CAMERA_HOSTNAME}
  TIMEZONE       = ${TIMEZONE}

################################
EOF

mkdir -p /tmp/restartd
touch /tmp/restartd/restartd
cp /mnt/data/restartd/restartd.conf /tmp/restartd
mount --bind /mnt/data/restartd/restartd /tmp/restartd/restartd
mount --rbind /tmp/restartd /mnt/data/restartd
echo "restartd \"/mnt/data/restartd/restartd\" \"/mnt/data/imi/imi_init/S99restartd restart\" \"/bin/echo 'restartd is running'\"" >> /mnt/data/restartd/restartd.conf

##################################################################################
## Syslog                                                                       ##
##################################################################################

echo "*** Enabling logging"

if [ "$ENABLE_LOGGING" -eq 1 ]
then
    $SD/firmware/init/S01logging restart
else
    $SD/firmware/init/S01logging stop
fi

wifi "$WIFI_SSID" "$WIFI_PASSWORD"

##################################################################################
## Set root Password                                                            ##
##################################################################################

if [ -n "${ROOT_PASSWORD}" ]
then
    echo "*** Setting root password... "
    echo "root:${ROOT_PASSWORD}" | chpasswd
else
    echo "WARN: root password must be set for SSH and or Telnet access"
fi

##################################################################################
## Set time zone                                                                ##
##################################################################################

if [ -n "${TIMEZONE}" ]
then
    echo "*** Configure time zone... "

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
    echo "*** Setting hostname... "
    echo "${CAMERA_HOSTNAME}" > /etc/hostname
    hostname "${CAMERA_HOSTNAME}"

    echo "*** Configuring new /etc/hosts file... "
    echo -e "127.0.0.1 \tlocalhost\n127.0.1.1 \t$CAMERA_HOSTNAME\n\n" > /etc/hosts

    if [ -f "$SD/firmware/etc/hosts" ]
    then
        echo "*** Appending $SD/firmware/etc/hosts to /etc/hosts"
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

) >> "${LOGFILE}" 2>&1
