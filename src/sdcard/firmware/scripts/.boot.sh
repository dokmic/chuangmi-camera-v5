#!/bin/sh
##################################################################################
## purpose: Start enabled services and stop with LED blinking                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################

SD_MOUNTDIR="/tmp/sd"

if [ -r "${SD_MOUNTDIR}/firmware/scripts/functions.sh" ]
then
    . "${SD_MOUNTDIR}/firmware/scripts/functions.sh"
else
    echo "Unable to load basic functions"
    exit 1
fi

export LOGFILE="${LOGDIR}/ft_boot.log"
export PATH="/tmp/sd/firmware/bin:$PATH"
export LD_LIBRARY_PATH=/tmp/sd/firmware/lib

(

echo "*** Executing /mnt/data/test/boot.sh... "

##################################################################################
## Put our bins into PATH                                                       ##
##################################################################################

if [ -d "${SD_MOUNTDIR}/firmware/bin" ] && ! mountpoint -q /tmp/sd/ft
then
    echo "*** Mounting ${SD_MOUNTDIR}/firmware/bin on /tmp/sd/ft... "
    mount --rbind "${SD_MOUNTDIR}/firmware/bin" /tmp/sd/ft
fi

##################################################################################
## Status LED                                                                   ##
##################################################################################

## This is required for initiating the GPIO pins

## Blue on
blue_led --enable

## IR Cut on
ir_cut     --enable

## Disable the others
yellow_led --disable
ir_led     --disable

##################################################################################
## Telnetd                                                                      ##
##################################################################################

if [ "${ENABLE_TELNETD}" -eq 1 ]
then
    sh ${SD_MOUNTDIR}/firmware/init/S99telnet start

    if ! grep -q '^telnetd' /tmp/etc/restartd.conf
    then
        echo "telnetd \"/usr/sbin/telnetd\" \"${SD_MOUNTDIR}/firmware/init/S99telnet restart\" \"/bin/echo '*** telnetd was restarted from restartd... '\"" >> /tmp/etc/restartd.conf
    fi
else
    sh ${SD_MOUNTDIR}/firmware/init/S99telnet stop
fi

##################################################################################
## NTPd                                                                         ##
##################################################################################

sh ${SD_MOUNTDIR}/firmware/init/S51ntpd start

if ! grep -q '^ntpd' /tmp/etc/restartd.conf
then
    echo "ntpd \"/usr/sbin/ntpd\" \"${SD_MOUNTDIR}/firmware/init/S51ntpd restart\" \"/bin/echo '*** NTPd was restarted from restartd... '\"" >> /tmp/etc/restartd.conf
fi

##################################################################################
## RTSP server                                                                  ##
##################################################################################

if [ "${ENABLE_RTSP}" -eq 1 ]
then
    sh ${SD_MOUNTDIR}/firmware/init/S99rtsp start
fi

##################################################################################
## Auto Night Mode                                                              ##
##################################################################################

if [ "${AUTO_NIGHT_MODE}" -eq 1 ]
then
    sh ${SD_MOUNTDIR}/firmware/init/S99auto_night_mode start
else
    sh ${SD_MOUNTDIR}/firmware/init/S99auto_night_mode stop

fi

##################################################################################
## MQTT                                                                         ##
##################################################################################

if [ "${ENABLE_MQTT}" -eq 1 ]
then
    sh ${SD_MOUNTDIR}/firmware/init/S99mqtt-interval start
    sh ${SD_MOUNTDIR}/firmware/init/S99mqtt-control  start
fi

##################################################################################
## Ceiling camera mode                                                          ##
##################################################################################

if [ "$CEILING_MODE" -eq 1 ]
then
    flipmode   --enable
    mirrormode --enable
fi

##################################################################################
## Cleanup                                                                      ##
##################################################################################

if [ -f /mnt/data/test/boot.sh ]
then
    rm /mnt/data/test/boot.sh
fi


) >> "${LOGFILE}" 2>&1

