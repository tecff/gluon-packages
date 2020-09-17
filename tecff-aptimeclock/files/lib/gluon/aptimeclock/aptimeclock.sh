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

ClientRadio0off="/tmp/${SCRIPTNAME}-ClientRadio0.off"
ClientRadio0on="/tmp/${SCRIPTNAME}-ClientRadio0.on"
APCLOCK_CONF_ON="wireless.radio0.client_clock_on"
APCLOCK_CONF_OFF="wireless.radio0.client_clock_off"

if [ ! $(uci get $APCLOCK_CONF_ON) ] || [ ! $(uci get $APCLOCK_CONF_OFF) ]; then
	$($DEBUG) && logger -s -t "$SCRIPTNAME" -p 5 "configuration is incomplete or doesn't exist."
	exit 0
fi

CurrentTime="$(date +%k%M)"

    apclock0on=$(uci get wireless.radio0.client_clock_on)
    apclock0off=$(uci get wireless.radio0.client_clock_off)
    if ( [ ${#apclock0on} -eq 4 ] ) && ( [ ${#apclock0off} -eq 4 ] ); then
      if ( ( ( [ $apclock0on -le $apclock0off ] ) && ( ( [ $CurrentTime -le $apclock0on ] ) || ( [ $CurrentTime -ge $apclock0off ] ) ) ) || ( ( [ $apclock0on -ge $apclock0off ] ) && ( ( [ $CurrentTime -le $apclock0on ] ) && ( [ $CurrentTime -ge $apclock0off ] ) ) ) ); then
        if [ $(uci get wireless.client_radio0.disabled) -eq 0 ]; then
          uci set wireless.client_radio0.disabled=1
          logger -s -t "$SCRIPTNAME" -p 5 "APradio0 deaktiviert"
          /sbin/wifi
          rm $ClientRadio0on &>/dev/null
          echo 1> $ClientRadio0off
        fi
      else
        if [ $(uci get wireless.client_radio0.disabled) -eq 1 ]; then
          uci set wireless.client_radio0.disabled=0
          logger -s -t "$SCRIPTNAME" -p 5 "APradio0 aktiviert"
          /sbin/wifi
          rm $ClientRadio0off &>/dev/null
          echo 1> $ClientRadio0on
        fi
      fi
    else
      logger -s -t "$SCRIPTNAME" -p 5 "wireless.radio0.client_clock_on or client_clock_off not set correctly to hhmm format."
    fi


dummy=$(uci get wireless.client_radio1.disabled)
if [ $? -eq 0 ]; then
  dummy=$(uci get wireless.radio0.client_clock_on)
  if [ $? -eq 0 ]; then
    apclock1on=$(uci get wireless.radio0.client_clock_on)
    apclock1off=$(uci get wireless.radio0.client_clock_off)
    if ( [ ${#apclock1on} -eq 4 ] ) && ( [ ${#apclock1off} -eq 4 ] ); then
      if ( ( ( [ $apclock1on -le $apclock1off ] ) && ( ( [ $CurrentTime -le $apclock1on ] ) || ( [ $CurrentTime -ge $apclock1off ] ) ) ) || ( ( [ $apclock1on -ge $apclock1off ] ) && ( ( [ $CurrentTime -le $apclock1on ] ) && ( [ $CurrentTime -ge $apclock1off ] ) ) ) ); then
        if [ $(uci get wireless.client_radio1.disabled) -eq 0 ]; then
          uci set wireless.client_radio1.disabled=1
          logger -s -t "$SCRIPTNAME" -p 5 "APradio1 deaktiviert"
          /sbin/wifi
          rm $ClientRadio0on &>/dev/null
          echo 1> $ClientRadio1off
        fi
      else
        if [ $(uci get wireless.client_radio1.disabled) -eq 1 ]; then
          uci set wireless.client_radio1.disabled=0
          logger -s -t "$SCRIPTNAME" -p 5 "APradio1 aktiviert"
          /sbin/wifi
          rm $ClientRadio0off &>/dev/null
          echo 1> $ClientRadio1on
        fi
      fi
    else
      logger -s -t "$SCRIPTNAME" -p 5 "wireless.radio0.client_clock_on or client_clock_off not set correctly to hhmm format."
    fi
  fi
fi

