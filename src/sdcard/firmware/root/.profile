# Set the LD library path
export LD_LIBRARY_PATH=/tmp/sd/firmware/lib

# load functions.sh
. /tmp/sd/firmware/scripts/functions.sh

# Deny no write access to terminal
mesg n || true
