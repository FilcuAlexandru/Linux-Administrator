#!/bin/bash
#
# Enable the administration channel
# Created: 2016-10-11 dkovacs of virtual7
#
# 2018-07-05    Separated ASERVER_HOME and MSERVER_HOME (dkovacs)
# 2018-08-03  Adapted for using configuration arrays  (dkovacs)
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

if [ "$HA_DOMAIN" == "true" ] && [ "$ADMIN_FLIP_ENABLED" == "true" ]; then
  # Bring up the Admin Server's floating IP
  admin_ip="$(getIPForName $ADMINSERVER_LISTENADDRESS)"
  netprefix="$(ip -o -f inet addr show $ADMIN_FLIP_IF | awk '{split($4, a, "/"); print a[2]}' | head -1)"
  sudo ip a add "$admin_ip/$netprefix" dev "$ADMIN_FLIP_IF"
  if  [ "$(up a|grep "inet $admin_ip")" ]; then
    msg "Activated floating IP $admin_ip on interface $ADMIN_FLIP_IF"
  else
    err "Failed to activate floating IP $admin_ip on interface $ADMIN_FLIP_IF"
    exit 1
  fi
fi

# Start the admin server
msg "Starting the Admin Server ..."
$ASERVER_HOME/startWebLogic.sh &
sleep 90   # TODO: find a more reliable way to wait until the admin server is completely started.

# Credentials will be passed as env. vars to wlst
export WLS_ADMIN_USER
export WLS_ADMIN_PW

# Activate the adminstration channel
msg "Activating the adminstration channel ..."
cat >$workdir/temp/configure_domain_2.py <<EOF
# Get parameters from the environment
wlsAdminUser=os.environ['WLS_ADMIN_USER']
wlsAdminPw=os.environ['WLS_ADMIN_PW']
connect(wlsAdminUser, wlsAdminPw ,'t3s://${LISTENADDRESS[$ADMINSERVER_NAME]}:${SSLPORT[$ADMINSERVER_NAME]}')
edit()
startEdit()

print('Activating the domain-wide administration channel ...')
cd('/')
cmo.setAdministrationPortEnabled(true)

activate()
disconnect()
EOF
$ASERVER_HOME/custom_scripts/wlst.sh $workdir/temp/configure_domain_2.py
rc=$((rc + $?))

msg "Stopping the Administration Server"
# Terminate the Administration Server process for this domain. Admin Servers
# of other domains have "virtual7.domainMarker" in the command line and will be
# ignored.
kill "$(ps x|grep "Dweblogic.Name=${ADMINSERVER_NAME}"|grep -v "Dvirtual7.domainMarker"|grep -v grep|awk '{print $1 }')" || exit 1
sleep 5

if [ "$HA_DOMAIN" == "true" ] && [ "$ADMIN_FLIP" == "true" ]; then
  # Bring down the Admin Server's floating IP
  admin_ip="$(getIPForName $ADMINSERVER_LISTENADDRESS)"
  netprefix="$(ip -o -f inet addr show $ADMIN_FLIP_IF | awk '{split($4, a, "/"); print a[2]}' | head -1)"
  sudo ip a del $admin_ip/$netprefix dev $ADMIN_FLIP_IF
fi

exit $rc
