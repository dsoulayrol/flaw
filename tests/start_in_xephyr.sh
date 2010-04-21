#!/bin/bash
# Run Awesome in a nested server for tests

[ $# -ne 1 ] && { echo "`basename $0` rc_file"; exit 0; }
[ -f $1 ] || { echo "\"$1\" does not exist"; exit 0; }

RC_FILE=$1
AWESOME=`which awesome`
XEPHYR=`which Xephyr`

test -x $AWESOME || { echo "Please install Awesome"; exit 1; }
test -x $XEPHYR || { echo "Please install Xephyr"; exit 1; }

echo "Starting $XEPHYR"
$XEPHYR -ac -br -noreset -screen 800x600 :1 &
sleep 1

echo "Starting $AWESOME with $RC_FILE"
DISPLAY=:1.0 $AWESOME -c $RC_FILE
