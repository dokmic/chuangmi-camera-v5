#!/bin/bash
INPUT="$1" ; shift
ARGUMENTS=$*

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
CONTAINER_IMAGE="miicam/miicam"

CACHEDIR="$HOME/.cache/miicam/src"
test -d "$CACHEDIR" || mkdir -p "$CACHEDIR"

DOCKER_CLI="docker run -i -v ${SCRIPTPATH}:/result -v ${CACHEDIR}:/env/src --detach=false --rm --tty=true"

## Print help output
function usage()
{
    cat <<EOF

    ${0} [--build|--build-docker|--shell|--all] <arguments>

    Manages the container build environment
    to cross compile binaries and build a firmware tarbal

    Options:

      --build          - Runs a container build and then executes make images clean
                         To create a MiiCam.zip and MiiCam.tgz
                         containing the binaries and other contents of the sdcard

      --build-docker   - Only (re)build the container environment

      --shell          - Opens a shell in the container build environment

      --release        - Create a new tag and release a new package version

      --open-links     - Open all download links in the browser

    Download toolchain: https://fliphess.com/toolchain/
    Repo: https://github.com/MiiCam/MiiCam

EOF

    return 0
}


## Nice output
function log()
{
    MESSAGE="$1"
    STRING=$(printf "%-60s" "*")

    echo "${STRING// /*}"
    echo "*** ${MESSAGE}"
    echo "${STRING// /*}"
}


## Error out
function die()
{
    log "ERROR - $@" > /dev/stderr
    exit 1
}


## Run a command in the container environment
function run()
{
    local COMMAND=$*

    exec $DOCKER_CLI $ARGUMENTS $CONTAINER_IMAGE /bin/bash -c "$COMMAND"

    return $?
}


## Build the container environment
function build_docker()
{
    log "Building docker container environment"

    docker build -t "${CONTAINER_IMAGE}" "${SCRIPTPATH}" $ARGUMENTS

    return $?
}


## Build the firmware image
function build()
{
    log "Building firmware image"

    run 'make images clean && mv /env/MiiCam.zip /env/MiiCam.tgz /result/'

    return $?
}

function open_links()
{
    [ -f "$SCRIPTPATH/sources.json" ] || die "Sources file $SCRIPTPATH/sources.json not found!"

    local LINKS="$( cat "$SCRIPTPATH/sources.json" | jq -r 'values[].website' )"

    echo "Opening links in browser....."
    for link in ${LINKS}; do
        open "$link"
    done
}

## Release a new version
function release()
{
   [ -x "$( command -v gitsem )" ] || die "This script depends on gitsem: go get github.com/Clever/gitsem"
   [ "$( git rev-parse --abbrev-ref HEAD )" == "master" ] || die "You are not on the master branch"
   [ "$( git diff --stat )" == '' ] || die "Git repo is dirrrrrrrty"

   echo "Releasing $VERSION"
   gitsem newversion
   echo "Don't forget to push your tags :)"
}

## Spawn a shell in the container environment
function shell()
{
    log "Opening a bash shell in the container environment"

    run /bin/bash

    return $?
}


function main()
{
    case "$INPUT"
    in
        --build)
            build
        ;;
        --build-docker)
            build_docker
        ;;
        --shell)
            shell
        ;;
        --newshell)
            build_docker
            shell
        ;;
        --release)
            release
        ;;
        --open-links)
            open_links
        ;;
	;;
        --all)
            build_docker
            build
        ;;
        *)
            usage
        ;;
    esac

    exit $?
}

main

