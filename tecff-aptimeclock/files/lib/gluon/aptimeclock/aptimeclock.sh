#!/bin/sh

#Check if ClientAP shall be limited

sleep 25 # this is a hack

SCRIPTNAME="aptimeclock"
DEBUG=false

# check if node has WLAN
if [ "$(ls -l /sys/class/ieee80211/phy* | wc -l)" -eq 0 ]; then
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "node has no WLAN, aborting."
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

PUBLIC_WLAN_ON_FILE="/tmp/${SCRIPTNAME}-public-wlan.on"
PUBLIC_WLAN_OFF_FILE="/tmp/${SCRIPTNAME}-public-wlan.off"
APCLOCK_CONF_ON="wireless.radio0.client_clock_on"
APCLOCK_CONF_OFF="wireless.radio0.client_clock_off"

if [ ! $(uci -q get $APCLOCK_CONF_ON) ] || [ ! $(uci -q get $APCLOCK_CONF_OFF) ]; then
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "configuration is incomplete or doesn't exist."
	exit 0
fi

APCLOCK_ON="$(uci get $APCLOCK_CONF_ON)"
APCLOCK_OFF="$(uci get $APCLOCK_CONF_OFF)"

CurrentTime="$(date +%H%M)"

WLAN_INTERFACES_OPEN="$(uci show wireless | cut -d"." -f2 | egrep "(client|owe)_radio[0-9]$" | uniq | tr '\n' ' ')"

for wlanif in $WLAN_INTERFACES_OPEN; do
	if ( [ ${#APCLOCK_ON} -eq 4 ] ) && ( [ ${#APCLOCK_OFF} -eq 4 ] ); then
		# following if clause is separated whether midnight is between the ON/OFF times
		if ( ( ( [ $APCLOCK_ON -le $APCLOCK_OFF ] ) && ( ( [ $CurrentTime -lt $APCLOCK_ON ] ) || ( [ $CurrentTime -ge $APCLOCK_OFF ] ) ) ) || \
			( ( [ $APCLOCK_ON -ge $APCLOCK_OFF ] ) && ( ( [ $CurrentTime -lt $APCLOCK_ON ] ) && ( [ $CurrentTime -ge $APCLOCK_OFF ] ) ) ) ); then
			if [ $(uci get wireless.${wlanif}.disabled) -eq 0 ]; then
				uci set wireless.${wlanif}.disabled=1
				logger -s -t "$SCRIPTNAME" -p 5 "${wlanif} deactivated"
				WLAN_DISABLE_TRIGGER=true
			fi
		else # node's time is currently in active public wlan timeframe
			if [ -f "$PUBLIC_WLAN_OFF_FILE" ]; then # public wlan has been deactivated before by this script
				logger -s -t "$SCRIPTNAME" -p 5 "${wlanif} activated"
				WLAN_ENABLE_TRIGGER=true
			fi
		fi
	else
		logger -s -t "$SCRIPTNAME" -p 5 "client_clock_on or client_clock_off not set correctly to hhmm format."
	fi
done
if [ "$WLAN_DISABLE_TRIGGER" = true ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "trigger wifi restart to disable the public wlan interfaces"
	wifi
	rm -f $PUBLIC_WLAN_ON_FILE &>/dev/null
	touch $PUBLIC_WLAN_OFF_FILE
	sleep 5 # wait for wifi command to finish
	uci revert wireless
fi
if [ "$WLAN_ENABLE_TRIGGER" = true ]; then
	logger -s -t "$SCRIPTNAME" -p 5 "trigger wifi restart to enable the public wlan interfaces"
	wifi
	rm -f $PUBLIC_WLAN_OFF_FILE &>/dev/null
	touch $PUBLIC_WLAN_ON_FILE
fi
