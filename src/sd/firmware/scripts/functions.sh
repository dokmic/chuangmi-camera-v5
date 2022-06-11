#!/bin/sh

##################################################################################
## purpose: standard library                                                    ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling, 2018                                                   ##
##################################################################################

LOGDIR="$SD/log"
LOGFILE="${LOGDIR}/ft_boot.log"
BASECFG="$SD/config.cfg"

if [ -f "${BASECFG}" ]
then
    . "${BASECFG}"
fi

##################################################################################
## System Functions                                                             ##
##################################################################################

## Logger function
log()
{
    echo "$( date ) - $*" | tee -a $LOGFILE
}

get_last_image()
{
    ## Find last created snapshot
    if [ -d $SD/RECORDED_IMAGES ]
    then
        find $SD/RECORDED_IMAGES/ -type f | sort -r | tail -n 1
    fi

    return $?
}


get_last_video()
{
    ## Find last created video
    if [ -d $SD/RECORDED_VIDEOS ]
    then
        find $SD/RECORDED_VIDEOS/ -type f | sort -r | tail -n 1
    fi

    return $?
}

##################################################################################
## Binary manipulation functions                                                ##
##################################################################################

## Creates /tmp/disable-binary
create_disable_binary()
{

    if [ ! -x /tmp/disable-binary ]
    then
        echo -e '#!/bin/sh\necho "$0 disabled with MiiCam"' > /tmp/disable-binary
        chmod +x /tmp/disable-binary
    fi
}

## Disable binary and optionally delete it from restartd.conf
disable_binary()
{
    BINARY="$1"
    RESTART="$2"

    create_disable_binary

    printf "*** Disabling %s... \n" "${1##*/}"

    if pgrep "${BINARY}" >/dev/null
    then
        pkill -9 "${BINARY}"
    fi

    if ! ( mount | grep -q "${BINARY}" )
    then
        mount --bind /tmp/disable-binary "${BINARY}"
    fi

    # update restartd.conf
    if [ -n "${RESTART}" ] && [ -f /mnt/data/restartd/restartd.conf ] && (grep -q ^"${RESTART} " /mnt/data/restartd/restartd.conf)
    then
        sed -i "/^${RESTART} /d" /mnt/data/restartd/restartd.conf
    fi
}

## Enable binary and optionally add it to restartd.conf
enable_binary()
{
    BINARY="$1"
    RESTART="$2"

    printf "*** Enabling %s... \n" "${1##*/}"

    if ( mount | grep -q "${BINARY}" )
    then
        umount "${BINARY}"
    fi

    # update restartd.conf
    if [ -n "${RESTART}" ] && [ -f /mnt/data/restartd/restartd.conf ] && ! grep -q ^"${RESTART} " /mnt/data/restartd/restartd.conf
    then
        grep ^"${RESTART} " /mnt/data/restartd/restartd.conf.bak >> /mnt/data/restartd/restartd.conf
    fi
}


##################################################################################
## Daemon functions                                                             ##
##################################################################################

## Start daemon
start_daemon()
{
    echo "*** Starting ${NAME} ${DESC}... "

    start-stop-daemon --start --quiet --oknodo --exec "${DAEMON}" -- ${DAEMON_OPTS}
    RC="$?"


    return "${RC}"
}

## Start a process as background daemon
start_daemon_background()
{
    echo "*** Starting ${NAME} ${DESC}... "

    start-stop-daemon --start --quiet --oknodo --pidfile "${PIDFILE}" --make-pidfile --background --exec "${DAEMON}" -- ${DAEMON_OPTS}
    RC="$?"

    return "${RC}"
}

## Stop daemon
stop_daemon()
{
    echo "*** Stopping ${NAME} ${DESC} ..."

    start-stop-daemon --stop --quiet --oknodo --pidfile "${PIDFILE}"
    RC="$?"

    return "${RC}"
}

## Stop background daemon
stop_daemon_background()
{
    stop_daemon

    if [ "${RC}" -eq 0 ] && [ -f "${PIDFILE}" ]
    then
        rm "${PIDFILE}"
    fi

    return "${RC}"
}

## Status of a daemon
status_daemon()
{
    PID="$( cat "${PIDFILE}" 2>/dev/null )"

    if [ "${PID}" ]
    then
        if kill -0 "${PID}" >/dev/null 2>/dev/null
        then
            echo "${DESC} is running with PID: ${PID}"
            RC="0"
        else
            echo "${DESC} is dead"
            RC="1"
        fi
    else
        echo "${DESC} is not running"
        RC="3"
    fi

    return "${RC}"
}

## Check for daemon executable
check_daemon_bin()
{
    BINARY="$1"
    DESC="$2"

    [ ! -x "$BINARY" ]  && return 1
    [ "x$DESC" == "x" ] && DESC="$BINARY"

    if [ ! -x "${BINARY}" ]
    then
        echo "Could not find ${DESC} binary"
        exit 1
    fi
}

## Print start-stop-daemon return status
ok_fail()
{
    INPUT="$1"

    if [ "$INPUT" -eq 0 ]
    then
        echo "OK"
    else
        echo "FAIL"
    fi
}


## Status of a daemon
get_daemon_state()
{
    DAEMON="$1"
    PIDFILE="/var/run/$DAEMON"
    PID="$( cat "${PIDFILE}" 2>/dev/null )"
    RC="$?"

    if [ "${PID}" ]
    then
        if kill -0 "${PID}" >/dev/null 2>/dev/null
        then
            echo "on"
        else
            echo "off"
        fi
    else
        echo "off"
    fi

    return "${RC}"
}


##################################################################################
## NVRAM Functions                                                              ##
##################################################################################

## get NVRAM variable
get_nvram()
{
    VARIABLE="$1"

    /usr/sbin/nvram get "${VARIABLE}" | xargs
    RC="$?"

    return "${RC}"
}

## Save NVRAM variable
set_nvram()
{
    VARIABLE="$1"
    VALUE="$2"

    [ "x$VARIABLE" == "x" ] || [ "x$VALUE" == "x" ] && return 1

    RC="0"

    if [ "$( get_nvram "${VARIABLE}" )" != "${VALUE}" ]
    then
        /usr/sbin/nvram set ${VARIABLE}="${VALUE}"
        RC="$?"
        /usr/sbin/nvram commit
        RC="$?"
    fi

    return "${RC}"
}

##################################################################################
## Create /var/run if nonexistent                                               ##
##################################################################################

if [ ! -d /var/run ]
then
    mkdir -p /var/run
fi

export FUNCTIONS_SOURCED=1

##################################################################################
## EOF                                                                          ##
##################################################################################
