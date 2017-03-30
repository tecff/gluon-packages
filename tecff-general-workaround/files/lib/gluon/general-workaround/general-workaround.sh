#!/bin/sh
#
# this script tries to recover nodes that have no gateway connectivity via IP
#

# don't do anything while an autoupdater process is running
checkupdater() {
	pgrep autoupdater >/dev/null
	if [ "$?" == "0" ]; then
		echo "autoupdater is running, aborting."
		exit
	fi
}

GWFILE="/tmp/gateway-ip-connection-active"
REBOOTFILE="/tmp/device-reboot-pending"

# check if the node can reach the default gateway
GWCONNECTION=0
echo "trying ping6 on NTP servers..."
for i in $(uci get system.ntp.server); do
	ping6 -c 1 $i >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "can ping at least one of the NTP servers: $i"
		GWCONNECTION=1
		if [ ! -f "$GWFILE" ]; then
			# create file so we can check later if there was a reachable gateway before
			touch $GWFILE
		fi
		break
	fi
done
if [ "$GWCONNECTION" -eq 0 ]; then
	echo "can't ping any of the NTP servers."
fi

DEVICEREBOOT=0
if [ "$GWCONNECTION" -eq 0 ]; then
	if [ -f "$GWFILE" ]; then
		# no pingable gateway but there was one before
		DEVICEREBOOT=1
	fi
fi

checkupdater

if [ ! -f "$REBOOTFILE" ] && [ "$DEVICEREBOOT" -eq 1 ]; then
	# delaying device reboot until the next script run
	touch $REBOOTFILE
	echo "device reboot possible on next script run."
elif [ "$DEVICEREBOOT" -eq 1 ]; then
	echo "rebooting device."
	[ "$GWCONNECTION" -eq 0 ] && rm -f $GWFILE
	rm -f $REBOOTFILE
	reboot
else
	echo "everything seems to be ok."
	rm -f $REBOOTFILE
fi
