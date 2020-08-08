#!/bin/sh
#
# this script tries to recover nodes that have problems with wlan connections
#
# limitations:
# - restarts every wlan radio device, not only affected ones
# - if all of	a) there are multiple radios
# 				b) at least one is not affected by the bug
# 				c) there are still batman clients using a working radio
# 				d) a gateway is reachable
# 		is true, this script fails to recover broken radios

SCRIPTNAME="broken-wlan-workaround"

# check if node has wlan
if [ "$(ls -l /sys/class/ieee80211/phy* | wc -l)" -eq 0 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "node has no wlan, aborting."
	exit
fi

# don't do anything while an autoupdater process is running
pgrep autoupdater >/dev/null
if [ "$?" == "0" ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "autoupdater is running, aborting."
	exit
fi

# don't run this script if another instance is still running
exec 200<$0
flock -n 200
if [ "$?" != "0" ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "failed to acquire lock, another instance of this script might still be running, aborting."
	exit
fi

# check if node uses a wlan driver and gather interfaces and devices
for i in $(ls /sys/class/net/); do
	# gather a list of interfaces
	if [ -n "$ATH9K_IFS" ]; then
		ATH9K_IFS="$ATH9K_IFS $i"
	else
		ATH9K_IFS="$i"
	fi
	# gather a list of devices
	if expr "$i" : "\(client\|ibss\|mesh\)[0-9]" >/dev/null; then
		ATH9K_UCI="$(uci show wireless | grep $i | cut -d"." -f1-2)"
		ATH9K_DEV="$(uci get ${ATH9K_UCI}.device)"
		if [ -n "$ATH9K_DEVS" ]; then
			if ! expr "$ATH9K_DEVS" : ".*${ATH9K_DEV}.*" >/dev/null; then
				ATH9K_DEVS="$ATH9K_DEVS $ATH9K_DEV"
			fi
		else
			ATH9K_DEVS="$ATH9K_DEV"
		fi
		ATH9K_UCI=
		ATH9K_DEV=
	fi
done

# check if the interface list is empty
if [ -z "$ATH9K_IFS" ] || [ -z "$ATH9K_DEVS" ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "node doesn't use a wlan driver, aborting."
	exit
fi

MESHFILE="/tmp/wlan-mesh-connection-active"
CLIENTFILE="/tmp/wlan-ff-client-connection-active"
PRIVCLIENTFILE="/tmp/wlan-priv-client-connection-active"
GWFILE="/tmp/gateway-connection-active"
RESTARTFILE="/tmp/wlan-restart-pending"
RESTARTINFOFILE="/tmp/wlan-last-restart-marker-file"

# check if there are connections to other nodes via wireless meshing
WLANMESHCONNECTIONS=0
for wlandev in $ATH9K_IFS; do
	if expr "$wlandev" : "\(ibss\|mesh\)[0-9]" >/dev/null; then
		if [ "$(batctl o | egrep "$wlandev" | wc -l)" -gt 0 ]; then
			WLANMESHCONNECTIONS=1
			logger -s -t "$SCRIPTNAME" -p 5	"found wlan mesh partners."
			if [ ! -f "$MESHFILE" ]; then
				# create file so we can check later if there was a wlan mesh connection before
				touch $MESHFILE
			fi
			break
		fi
	fi
done

# check if there are local wlan batman clients
WLANFFCONNECTIONS=0
WLANFFCONNECTIONCOUNT="$(batctl tl | grep W | wc -l)"
if [ "$WLANFFCONNECTIONCOUNT" -gt 0 ]; then
	# note: this check doesn't know which radio the clients are on
	WLANFFCONNECTIONS=1
	logger -s -t "$SCRIPTNAME" -p 5 "found batman local clients."
	if [ ! -f "$CLIENTFILE" ]; then
		# create file so we can check later if there were batman local clients before
		touch $CLIENTFILE
	fi
fi

# check for clients on private wlan device
WLANPRIVCONNECTIONS=0
for wlandev in $ATH9K_IFS; do
	if expr "$wlandev" : "wlan[0-9]" >/dev/null; then
		iw dev $wlandev station dump 2>/dev/null | grep -q Station
		if [ "$?" == "0" ]; then
			WLANPRIVCONNECTIONS=1
			logger -s -t "$SCRIPTNAME" -p 5 "found private wlan clients."
			if [ ! -f "$PRIVCLIENTFILE" ]; then
				# create file so we can check later if there were private wlan clients before
				touch $PRIVCLIENTFILE
			fi
			break
		fi
	fi
done

# check if the node can reach the default gateway
GWCONNECTION=0
GATEWAY=$(batctl gwl | grep -e "^=>" -e "^\*" | awk -F'[ ]' '{print $2}')
if [ $GATEWAY ]; then
	batctl ping -c 2 $GATEWAY >/dev/null 2>&1
	if [ "$?" == "0" ]; then
		logger -s -t "$SCRIPTNAME" -p 5 "can ping default gateway $GATEWAY , trying ping6 on NTP servers..."
		for i in $(uci get system.ntp.server); do
			ping6 -c 1 $i >/dev/null 2>&1
			if [ $? -eq 0 ]; then
				logger -s -t "$SCRIPTNAME" -p 5	"can ping at least one of the NTP servers: $i"
				GWCONNECTION=1
				if [ ! -f "$GWFILE" ]; then
					# create file so we can check later if there was a reachable gateway before
					touch $GWFILE
				fi
				break
			fi
		done
		if [ "$GWCONNECTION" -eq 0 ]; then
			logger -s -t "$SCRIPTNAME" -p 5 "can't ping any of the NTP servers."
		fi
	else
		logger -s -t "$SCRIPTNAME" -p 5 "can't ping default gateway $GATEWAY ."
	fi
else
	echo "no default gateway defined."
fi

WLANRESTART=0
if [ "$WLANMESHCONNECTIONS" -eq 0 ] && [ "$WLANPRIVCONNECTIONS" -eq 0 ] && [ "$WLANFFCONNECTIONS" -eq 0 ]; then
	if [ -f "$MESHFILE" ] || [ -f "$CLIENTFILE" ] || [ -f "$PRIVCLIENTFILE" ]; then
		# no wlan connections but there was one before
		WLANRESTART=1
	fi
fi
if [ "$GWCONNECTION" -eq 0 ]; then
	if [ -f "$GWFILE" ]; then
		# no pingable gateway but there was one before
		WLANRESTART=1
	fi
fi

if [ ! -f "$RESTARTFILE" ] && [ "$WLANRESTART" -eq 1 ]; then
	# delaying wlan restart until the next script run
	touch $RESTARTFILE
	logger -s -t "$SCRIPTNAME" -p 5 "wlan restart possible on next script run."
elif [ "$WLANRESTART" -eq 1 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "restarting wlan."
	[ "$GWCONNECTION" -eq 0 ] && rm -f $GWFILE
	rm -f $MESHFILE
	rm -f $CLIENTFILE
	rm -f $PRIVCLIENTFILE
	rm -f $RESTARTFILE
	touch $RESTARTINFOFILE
	for wlandev in $ATH9K_DEVS; do
		wifi down $wlandev
	done
	sleep 1
	for wlandev in $ATH9K_DEVS; do
		wifi up $wlandev
	done
else
	logger -s -t "$SCRIPTNAME" -p 5 "everything seems to be ok."
	rm -f $RESTARTFILE
fi
