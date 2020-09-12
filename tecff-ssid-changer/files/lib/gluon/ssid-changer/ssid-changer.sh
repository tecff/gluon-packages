#!/bin/sh

SCRIPTNAME="ssid-changer"

# check if node has WLAN
if [ "$(ls -l /sys/class/ieee80211/phy* | wc -l)" -eq 0 ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "node has no WLAN, aborting."
	exit
fi

# don't do anything while an autoupdater process is running
pgrep -f autoupdater >/dev/null
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

ONLINE_SSID="$(uci -q get wireless.client_radio0.ssid)"
: ${ONLINE_SSID:=Freifunk}   # if ONLINE_SSID is NULL
OFFLINE_PREFIX='FF_OFFLINE_' # use something short to leave space for the nodename
UPPER_LIMIT='30' # above this limit the online SSID will be used
LOWER_LIMIT='15' # below this limit the offline SSID will be used
# in-between these two values the SSID will never be changed to prevent it from toggling every minute.

# generate an Offline SSID with the first and last part of the node's name to be able to recognise which node is down
NODENAME="$(uname -n)"
if [ "${#NODENAME}" -gt "$((30 - ${#OFFLINE_PREFIX}))" ] ; then
	HALF="$(( (28 - ${#OFFLINE_PREFIX} ) / 2 ))" # calculate the length of the first part of the node identifier in the offline-ssid
	SKIP="$(( ${#NODENAME} - $HALF ))" # jump to this character for the last part of the name
	OFFLINE_SSID="$OFFLINE_PREFIX${NODENAME:0:$HALF}...${NODENAME:$SKIP:${#NODENAME}}" # use the first and last part of the nodename for nodes with long names
else
	OFFLINE_SSID="$OFFLINE_PREFIX$NODENAME" # it's possible to use the full name in the offline ssid
fi

# check for an active gateway and get its connection quality (TQ)
GATEWAY_TQ="$(batctl gwl | grep -e "^=>" -e "^\*" | awk -F'[()]' '{print $2}'| tr -d " ")"

# initialize empty variables
[ -n "$GATEWAY_TQ" ] || GATEWAY_TQ=0
[ -n "$HUP_NEEDED" ] || HUP_NEEDED=false

if [ "$GATEWAY_TQ" -gt "$UPPER_LIMIT" ];
then
	logger -s -t "$SCRIPTNAME" -p 5 "gateway TQ is ${GATEWAY_TQ}, node is online"
	for HOSTAPD in $(ls /var/run/hostapd-phy*); do # check status of all physical WLAN devices
		CURRENT_SSID="$(grep "^ssid=${ONLINE_SSID}$" $HOSTAPD | cut -d"=" -f2)"
		if [ "$CURRENT_SSID" == "$ONLINE_SSID" ]
		then
			HUP_NEEDED=false
			continue
		fi
		CURRENT_SSID="$(grep "^ssid=${OFFLINE_SSID}$" $HOSTAPD | cut -d"=" -f2)"
		if [ "$CURRENT_SSID" == "$OFFLINE_SSID" ]
		then
			logger -s -t "$SCRIPTNAME" -p 5 "TQ is ${GATEWAY_TQ}, SSID is ${CURRENT_SSID}, changing to ${ONLINE_SSID}"
			sed -i "s/^ssid=${CURRENT_SSID}$/ssid=${ONLINE_SSID}/" $HOSTAPD
			HUP_NEEDED=true # immediate HUP would be too early for dualband devices, delaying it
		else
			logger -s -t "$SCRIPTNAME" -p 5 "there's something wrong, didn't find SSID ${ONLINE_SSID} or ${OFFLINE_SSID} in ${HOSTAPD}"
		fi
	done
fi

if [ "$GATEWAY_TQ" -lt "$LOWER_LIMIT" ];
then
	logger -s -t "$SCRIPTNAME" -p 5 "gateway TQ is ${GATEWAY_TQ}, node is considered offline"
	for HOSTAPD in $(ls /var/run/hostapd-phy*); do # check status of all physical WLAN devices
		CURRENT_SSID="$(grep "^ssid=${OFFLINE_SSID}$" $HOSTAPD | cut -d"=" -f2)"
		if [ "$CURRENT_SSID" == "$OFFLINE_SSID" ]
		then
			HUP_NEEDED=false
			continue
		fi
		CURRENT_SSID="$(grep "^ssid=${ONLINE_SSID}$" $HOSTAPD | cut -d"=" -f2)"
		if [ "$CURRENT_SSID" == "$ONLINE_SSID" ]
		then
			logger -s -t "$SCRIPTNAME" -p 5 "TQ is ${GATEWAY_TQ}, SSID is ${CURRENT_SSID}, changing to ${OFFLINE_SSID}"
			sed -i "s/^ssid=${ONLINE_SSID}$/ssid=${OFFLINE_SSID}/" $HOSTAPD
			HUP_NEEDED=true # immediate HUP would be too early for dualband devices, delaying it
		else
			logger -s -t "$SCRIPTNAME" -p 5 "there's something wrong, didn't find SSID ${ONLINE_SSID} or ${OFFLINE_SSID} in ${HOSTAPD}"
		fi
	done
fi

# don't do anything if the TQ is between the two thresholds
if [ "$GATEWAY_TQ" -ge "$LOWER_LIMIT" -a "$GATEWAY_TQ" -le "$UPPER_LIMIT" ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "TQ ${GATEWAY_TQ} is between the the lower&upper limits, doing nothing"
	HUP_NEEDED=false
fi

if [ "$HUP_NEEDED" = true ]; then
	killall -HUP hostapd # sending HUP signal to all hostapd processes in order to use the changed SSID
	logger -s -t "$SCRIPTNAME" -p 5 "reloading hostapd with HUP"
fi
