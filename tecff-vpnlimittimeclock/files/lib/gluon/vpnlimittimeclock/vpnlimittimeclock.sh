#!/bin/sh

#turn on the bandwidth limiter on meshvpn link by schedule. 

sleep 37 # this is a hack

vpnlimitoff="/tmp/vpnlimit.off"
vpnlimiton="/tmp/vpnlimit.on"

CurrentTime="$(date +%k%M)"

dummy=$(uci get mesh_vpn.bandwidth_limit.enabled)
if [ $? -eq 0 ]; then
  dummy=$(uci get mesh_vpn.bandwidth_limit.clock_on)
  if [ $? -eq 0 ]; then
    vpnlimiton=$(uci get mesh_vpn.bandwidth_limit.clock_on)
    vpnlimitoff=$(uci get mesh_vpn.bandwidth_limit.clock_off)
    if ( [ ${#vpnlimiton} -eq 4 ] ) && ( [ ${#vpnlimitoff} -eq 4 ] ); then
      if ( ( ( [ $vpnlimiton -le $vpnlimitoff ] ) && ( ( [ $CurrentTime -ge $vpnlimiton ] ) && ( [ $CurrentTime -le $vpnlimitoff ] ) ) ) || ( ( [ $vpnlimiton -ge $vpnlimitoff ] ) && ( ( [ $CurrentTime -ge $vpnlimiton ] ) || ( [ $CurrentTime -le $vpnlimitoff ] ) ) ) ); then
        if [ $(uci get mesh_vpn.bandwidth_limit.enabled) -eq 0 ]; then
          uci set mesh_vpn.bandwidth_limit.enabled=1
          logger -s -t "tecff-vpnlimittimeclock" -p 5 "VPN-bandwidthlimit aktiviert"
          /etc/init.d/fastd restart
          rm $vpnlimitoff &>/dev/null
          echo 1> $vpnlimiton
        fi
      else
        if [ $(uci get mesh_vpn.bandwidth_limit.enabled) -eq 1 ]; then
          uci set mesh_vpn.bandwidth_limit.enabled=0
          logger -s -t "tecff-vpnlimittimeclock" -p 5 "VPN-bandwidthlimit deaktiviert"
          /etc/init.d/fastd restart
          rm $vpnlimiton &>/dev/null
          echo 1> $vpnlimitoff
        fi
      fi
    else
      logger -s -t "tecff-vpnlimittimeclock" -p 5 "mesh_vpn.bandwidth_limit.clock_on or mesh_vpn.bandwidth_limit.clock_off not set correctly to hhmm format."
    fi
  fi
fi

