#!/bin/sh

#turn on the bandwidth limiter on meshvpn link by schedule. 

sleep 37 # this is a hack

SCRIPTNAME="vpnlimittimeclock"

vpnlimitoff="/tmp/${SCRIPTNAME}.off"
vpnlimiton="/tmp/${SCRIPTNAME}.on"

CurrentTime="$(date +%k%M)"

vpnlimit=$(uci get gluon.mesh_vpn.limit_enabled)
if [ $? -eq 0 ]; then
  vpnlimiton=$(uci -q get gluon.mesh_vpn.limit_clock_on)
  if [ $? -eq 0 ]; then
    vpnlimitoff=$(uci get gluon.mesh_vpn.limit_clock_off)
    if ( [ ${#vpnlimiton} -eq 4 ] ) && ( [ ${#vpnlimitoff} -eq 4 ] ); then
      if ( ( ( [ $vpnlimiton -le $vpnlimitoff ] ) && ( ( [ $CurrentTime -ge $vpnlimiton ] ) && ( [ $CurrentTime -le $vpnlimitoff ] ) ) ) || ( ( [ $vpnlimiton -ge $vpnlimitoff ] ) && ( ( [ $CurrentTime -ge $vpnlimiton ] ) || ( [ $CurrentTime -le $vpnlimitoff ] ) ) ) ); then
        if [ $vpnlimit -eq 0 ]; then
          uci set gluon.mesh_vpn.limit_enabled=1
          logger -s -t "$SCRIPTNAME" -p 5 "VPN-bandwidthlimit aktiviert"
          /etc/init.d/fastd restart
          rm $vpnlimitoff &>/dev/null
          echo 1> $vpnlimiton
        fi
      else
        if [ $vpnlimit -eq 1 ]; then
          uci set gluon.mesh_vpn.limit_enabled=0
          logger -s -t "$SCRIPTNAME" -p 5 "VPN-bandwidthlimit deaktiviert"
          /etc/init.d/fastd restart
          rm $vpnlimiton &>/dev/null
          echo 1> $vpnlimitoff
        fi
      fi
    else
      logger -s -t "$SCRIPTNAME" -p 5 "gluon.mesh_vpn.limit_clock_on or gluon.mesh_vpn.limit_clock_off not set correctly to hhmm format."
    fi
  fi
fi
