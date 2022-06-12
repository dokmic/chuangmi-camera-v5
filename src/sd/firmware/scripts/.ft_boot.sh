#!/bin/sh -l

##################################################################################
## purpose: Initialize the Chuangmi 720P hack                                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################

cp -r $SD/firmware/etc/* /etc
. /etc/profile

LOGDIR=$SD/log
LOGFILE=$LOGDIR/ft_boot.log
mkdir -p $LOGDIR

##################################################################################
## Config                                                                       ##
##################################################################################

if [ ! -f "$SD/config.cfg" ]
then
    echo "Config not found, starting normal boot sequence." | tee -a "${LOGFILE}"
    echo 0 > /tmp/ft_mode
    vg_boot
    exit
fi

## Load the config file
. "$SD/config.cfg"

if [ "${?}" -ne 0 ]
then
    echo "Failed to load $SD/config.cfg, starting normal boot sequence" | tee -a "${LOGFILE}"
    echo 0 > /tmp/ft_mode
    vg_boot
    exit
fi

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

##################################################################################
## WIFI                                                                         ##
##################################################################################

echo "*** Setting up WIFI configuration"

if [ -s "$SD/firmware/scripts/configure_wifi" ]
then
    echo "*** Configuring WIFI... "
    sh "$SD/firmware/scripts/configure_wifi"
fi

##################################################################################
## Mount GMLIB configuration                                                    ##
##################################################################################

echo "*** Setting up our own gmlib config"

if [ -f $SD/firmware/etc/gmlib.cfg ]
then
    mount --rbind $SD/firmware/etc/gmlib.cfg /gm/config/gmlib.cfg
fi

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

##################################################################################
## Prepare restartd.conf                                                        ##
##################################################################################

if [ ! -f /mnt/data/restartd/restartd.conf.bak ] && mountpoint -q /etc
then
    cp /mnt/data/restartd/restartd.conf /mnt/data/restartd/restartd.conf.bak
fi

##################################################################################
## Disable Cloud Services and OTA                                               ##
##################################################################################

if [ "${DISABLE_CLOUD}" -eq 1 ]
then
    $SD/firmware/init/S50disable_cloud start
    $SD/firmware/init/S50disable_ota start

elif [ "${DISABLE_OTA}" -eq 1 ]
then
    $SD/firmware/init/S50disable_ota start
else
    $SD/firmware/init/S50disable_ota stop
fi

##################################################################################
## Start enabled Services                                                       ##
##################################################################################

if ! [ -f /mnt/data/test/boot.sh ]
then
    ln -s -f $SD/firmware/scripts/.boot.sh /mnt/data/test/boot.sh
fi

) >> "${LOGFILE}" 2>&1
