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
