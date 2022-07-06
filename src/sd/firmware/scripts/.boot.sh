#!/bin/sh -l
##################################################################################
## purpose: Start enabled services and stop with LED blinking                   ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling , 2017                                                  ##
##################################################################################

(
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

echo "ntpd \"ntpd\" \"$SD/firmware/init/S51ntpd start\" \"/bin/echo 'ntpd is running'\"" >> /mnt/data/restartd/restartd.conf

if [ "${NIGHT_MODE:-AUTO}" = AUTO ]; then
  $SD/firmware/init/S99auto_night_mode start
else
  $SD/firmware/init/S99auto_night_mode stop
  night_mode $([ "$NIGHT_MODE" -eq 1 ] && echo --enable || echo --disable)
fi

[ "${ENABLE_MQTT:-0}" -eq 1 ] && $SD/firmware/init/S99mqtt start
[ "${ENABLE_RTSP:-0}" -eq 1 ] && $SD/firmware/init/S99rtspd start

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


) | logger -t firmware
