#!/bin/sh
#
# this script tries to recover nodes that have no gateway connectivity via IP
#

SCRIPTNAME="general-workaround"
DEBUG=false

# don't do anything while an autoupdater process is running
checkupdater() {
	pgrep autoupdater >/dev/null
	if [ "$?" == "0" ]; then
		logger -s -t "$SCRIPTNAME" -p 5 "autoupdater is running, aborting."
		exit
	fi
}

GWFILE="/tmp/gateway-ip-connection-active"
NWRESTARTFILE="/tmp/network-restart-pending"
REBOOTFILE="/tmp/device-reboot-pending"

# check if the node can reach an NTP server
IPV6CONNECTION=0
$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "checking reachability of NTP servers..."
if [ -f /var/gluon/state/can_reach_ntp ]; then
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "can ping at least one of the NTP servers."
	IPV6CONNECTION=1
	if [ ! -f "$GWFILE" ]; then
		# create file so we can check later if there was a reachable gateway before
		touch $GWFILE
	fi
fi
if [ "$IPV6CONNECTION" -eq 0 ]; then
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "can't ping any of the NTP servers."
fi

# check if the node suffers from a unregister_netdevice bug
UNREGISTERBUG=0
$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "checking for unregister_netdevice bug..."
dmesg | tail | grep -q "unregister_netdevice: waiting for"
if [ "$?" == 0 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "seeing log messages which indicate a serious bug."
	UNREGISTERBUG=1
fi

# determine if the script has to act
ACTIONREQUIRED=0
if [ "$IPV6CONNECTION" -eq 0 ] || [ "$UNREGISTERBUG" -eq 1 ]; then
	if [ -f "$GWFILE" ]; then
		# no pingable gateway but there was one before
		ACTIONREQUIRED=1
		logger -s -t "$SCRIPTNAME" -p 5 "detected a reason to act upon."
	else
		# no pingable gateway but there also was none before
		$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "detected a reason to act upon, but as this node had no gateway since its last reboot, doing nothing."
	fi
fi

checkupdater

if [ ! -f "$REBOOTFILE" ] && [ ! -f "$NWRESTARTFILE" ] && [ "$ACTIONREQUIRED" -eq 1 ]; then
	# delaying network restart until the next script run
	touch $NWRESTARTFILE
	logger -s -t "$SCRIPTNAME" -p 5 "network restart possible on next script run."
elif [ ! -f "$REBOOTFILE" ] && [ "$ACTIONREQUIRED" -eq 1 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "restarting device network."
	# create marker file to reboot if problem persists until next script run
	touch $REBOOTFILE
	/etc/init.d/network restart
elif [ "$ACTIONREQUIRED" -eq 1 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "rebooting device, network restart didn't help."
	reboot
else
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "everything seems to be ok."
	rm -f $REBOOTFILE
	rm -f $NWRESTARTFILE
fi
