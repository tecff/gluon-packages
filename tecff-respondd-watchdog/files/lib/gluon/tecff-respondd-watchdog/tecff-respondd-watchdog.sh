#!/bin/sh
#
# this script starts gluon-respondd if it isn't running
#

# don't do anything while an autoupdater process is running
pgrep autoupdater >/dev/null
if [ "$?" == "0" ]; then
	echo "autoupdater is running, aborting."
	exit
fi

# don't run this script if another instance is still running
# this uses two separate lock files to make the script exit instead of waiting for a lock
cleanup() {
	echo "Cleaning stuff up..."
	rm /var/lock/tecff-respondd-watchdog.lock-long
	exit
}
lock /var/lock/tecff-respondd-watchdog.lock-short
if [ -e /var/lock/tecff-respondd-watchdog.lock-long ]; then
	lock -u /var/lock/tecff-respondd-watchdog.lock-short
	echo "another instance of this script is already running, aborting."
	exit
fi
touch /var/lock/tecff-respondd-watchdog.lock-long
lock -u /var/lock/tecff-respondd-watchdog.lock-short
trap cleanup INT TERM

RESTARTINFOFILE="/tmp/respondd-last-watchdog-start-marker-file"

# start respondd if it isn't running
pgrep respondd >/dev/null
if [ "$?" != "0" ]; then
	echo "respondd isn't running, starting it."
	/etc/init.d/gluon-respondd start
	touch $RESTARTINFOFILE
fi

cleanup
