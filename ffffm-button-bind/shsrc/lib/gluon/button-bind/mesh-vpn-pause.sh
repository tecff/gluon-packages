#!/bin/sh

# called by FUNCTION = 6 (mesh-VPN OFF) for 5 hours

/etc/init.d/fastd stop && sleep 18000 && /etc/init.d/fastd start
