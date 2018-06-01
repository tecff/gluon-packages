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
NWRESTARTFILE="/tmp/network-restart-pending"
REBOOTFILE="/tmp/device-reboot-pending"

# check if the node can reach an NTP server
IPV6CONNECTION=0
echo "trying ping6 on NTP servers..."
for i in $(uci get system.ntp.server); do
	ping6 -c 1 $i >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "can ping at least one of the NTP servers: $i"
		IPV6CONNECTION=1
		if [ ! -f "$GWFILE" ]; then
			# create file so we can check later if there was a reachable gateway before
			touch $GWFILE
		fi
		break
	fi
done
if [ "$IPV6CONNECTION" -eq 0 ]; then
	echo "can't ping any of the NTP servers."
fi

# check if the node suffers from a unregister_netdevice bug
UNREGISTERBUG=0
echo "checking for unregister_netdevice bug..."
dmesg | tail | grep -q "unregister_netdevice: waiting for"
if [ "$?" == 0 ]; then
	echo "seeing log messages which indicate a serious bug."
	UNREGISTERBUG=1
fi

# determine if the script has to act
ACTIONREQUIRED=0
if [ "$IPV6CONNECTION" -eq 0 ] || [ "$UNREGISTERBUG" -eq 1 ]; then
	echo "detected a reason to act upon."
	if [ -f "$GWFILE" ]; then
		# no pingable gateway but there was one before
		ACTIONREQUIRED=1
	fi
fi

checkupdater

if [ ! -f "$REBOOTFILE" ] && [ ! -f "$NWRESTARTFILE" ] && [ "$ACTIONREQUIRED" -eq 1 ]; then
	# delaying network restart until the next script run
	touch $NWRESTARTFILE
	echo "network restart possible on next script run."
elif [ ! -f "$REBOOTFILE" ] && [ "$ACTIONREQUIRED" -eq 1 ]; then
	echo "restarting device network."
	# create marker file to reboot if problem persists until next script run
	touch $REBOOTFILE
	/etc/init.d/network restart
elif [ "$ACTIONREQUIRED" -eq 1 ]; then
	echo "rebooting device, network restart didn't help."
	reboot
else
	echo "everything seems to be ok."
	rm -f $REBOOTFILE
	rm -f $NWRESTARTFILE
fi
