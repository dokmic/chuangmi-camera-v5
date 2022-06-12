#!/bin/sh -l
##################################################################################
## purpose: Start enabled services and stop with LED blinking                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################

if [ -r "$SD/firmware/scripts/functions.sh" ]
then
    . "$SD/firmware/scripts/functions.sh"
else
    echo "Unable to load basic functions"
    exit 1
fi

export LOGFILE="${LOGDIR}/ft_boot.log"

(

echo "*** Executing /mnt/data/test/boot.sh... "

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

if [ "${ENABLE_TELNETD:-0}" -eq 1 ]
then
  /mnt/data/imi/imi_init/S50telnet start

  if ! grep -q '^telnetd' /mnt/data/restartd/restartd.conf
  then
    echo "telnetd \"/usr/sbin/telnetd\" \"/mnt/data/imi/imi_init/S50telnet restart\" \"/bin/echo '*** telnetd was restarted from restartd... '\"" >> /mnt/data/restartd/restartd.conf
    if pgrep restartd >/dev/null
    then
        /mnt/data/imi/imi_init/S99restartd restart
    fi
  fi
fi

##################################################################################
## NTPd                                                                         ##
##################################################################################

$SD/firmware/init/S51ntpd start

if ! grep -q '^ntpd' /mnt/data/restartd/restartd.conf
then
    echo "ntpd \"/usr/sbin/ntpd\" \"$SD/firmware/init/S51ntpd restart\" \"/bin/echo '*** NTPd was restarted from restartd... '\"" >> /mnt/data/restartd/restartd.conf
fi

##################################################################################
## RTSP server                                                                  ##
##################################################################################

if [ "${ENABLE_RTSP}" -eq 1 ]
then
    $SD/firmware/init/S99rtsp start
fi

##################################################################################
## Auto Night Mode                                                              ##
##################################################################################

if [ "${AUTO_NIGHT_MODE:-1}" -eq 1 ]
then
    $SD/firmware/init/S99auto_night_mode start
else
    $SD/firmware/init/S99auto_night_mode stop

fi

##################################################################################
## MQTT                                                                         ##
##################################################################################

if [ "${ENABLE_MQTT}" -eq 1 ]
then
    $SD/firmware/init/S99mqtt start
fi

##################################################################################
## Ceiling camera mode                                                          ##
##################################################################################

if [ "$CEILING_MODE" -eq 1 ]
then
    flip_mode   --enable
    mirror_mode --enable
fi

##################################################################################
## Cleanup                                                                      ##
##################################################################################

if [ -f /mnt/data/test/boot.sh ]
then
    rm /mnt/data/test/boot.sh
fi


) >> "${LOGFILE}" 2>&1

