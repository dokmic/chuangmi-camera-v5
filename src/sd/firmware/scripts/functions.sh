#!/bin/sh -l

##################################################################################
## purpose: standard library                                                    ##
## license: GPLv3+, http://www.gnu.org/licenses/gpl-3.0.html                    ##
## author: Jan Sperling, 2018                                                   ##
##################################################################################

LOGDIR="$SD/log"
LOGFILE="${LOGDIR}/ft_boot.log"

##################################################################################
## System Functions                                                             ##
##################################################################################

## Logger function
log()
{
    echo "$( date ) - $*" | tee -a $LOGFILE
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
