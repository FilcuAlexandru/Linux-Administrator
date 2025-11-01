#!/bin/bash
#
# Verify installation prerequisites.

cd "$(dirname $0)/.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Checking installation prerequisites ..."

# Check if configuration parameters are set
error=0
[ "$WLS_OS_USER" ] || { err "Missing configuration: WLS_OS_USER"; error=1; }
[ "$WLS_INSTALL_TYPE" == "generic-12c" ] || [ "$WLS_INSTALL_TYPE" == "generic-14c" ] || [ "$WLS_INSTALL_TYPE" == "infrastructure-12c" ] || [ "$WLS_INSTALL_TYPE" == "soa-12c" ] || { err "Missing or invalid configuration: WLS_INSTALL_TYPE"; error=1; }
[ "$DOMAIN_NAME" ] || { err "Missing configuration: DOMAIN_NAME"; error=1; }
[ "$WLS_OPERATOR_USER" ] || { err "Missing configuration: WLS_OPERATOR_USER"; error=1; }
[ "$ADMIN_CHANNEL_ENABLED" == "true" ] || [ "$ADMIN_CHANNEL_ENABLED" == "false" ] || { err "Missing or invalid configuration: ADMIN_CHANNEL_ENABLED"; error=1; }
[ "${#NM_LISTENADDRESS[@]}" -gt 0 ] || { err "Missing configuration: NM_LISTENADDRESS"; error=1; }
[ "$NM_PORT" ] || { err "Missing configuration: NM_PORT"; error=1; }
[ "$SOFTWARE_REPO_PATH" ] || { err "Missing configuration: SOFTWARE_REPO_PATH"; error=1; }
[ "$LOGDIR_PATH" ] || { err "Missing configuration: LOGDIR_PATH"; error=1; }
[ "$ADMINSERVER_NAME" ] || { err "Missing configuration: ADMINSERVER_NAME"; error=1; }
[ "$error" -ne 0 ] && exit 1

if [ "$HA_DOMAIN" == "true" ]; then
  [ "$SHAREDSTORAGE_PATH" ] || { err "Missing configuration: SHAREDSTORAGE_PATH"; error=1; }
  [ "$ADMIN_FLIP_ENABLED" == "true" ] || [ "$ADMIN_FLIP_ENABLED" == "false" ] || { err "Missing or invalid configuration: ADMIN_FLIP_ENABLED"; error=1; }
  if [ "$ADMIN_FLIP_ENABLED" == "true" ]; then
    [ "$ADMIN_FLIP_IF" ] || { err "Missing configuration: ADMIN_FLIP_IF"; error=1; }
  fi
fi


# Check if required server configuration parameters exist in the respective associative arrays
# Loop over all servers. Keys retrieved from the different associative arrays are all considered as server names.
for server in $(echo "$ADMINSERVER_NAME" "${!LISTENADDRESS[@]}" "${!LISTENPORT[@]}" "${!SSLPORT[@]}" "${!ADMINPORT[@]}" "${!MACHINE[@]}" "${!CLUSTER[@]}"|tr ' ' '\n'|sort|uniq); do
  [ "${LISTENADDRESS[$server]}" ] || { err "Missing configuration: LISTENADDRESS[$server]"; error=1; }
  [ "${LISTENPORT[$server]}" ] || { err "Missing configuration: LISTENPORT[$server]"; error=1; }
  [ "${SSLPORT[$server]}" ] || { err "Missing configuration: SSLPORT[$server]"; error=1; }
  [ "${ADMINPORT[$server]}" ] || { err "Missing configuration: ADMINPORT[$server]"; error=1; }
  if [ "$server" != "$ADMINSERVER_NAME" ]; then
    [ "${MACHINE[$server]}" ] || { err "Missing configuration: MACHINE[$server]"; error=1; }
  else
    [ "${CLUSTER[$server]}" ] && { err "Invalid configuration: CLUSTER[$server]. The Administration Server must not be a member of any cluster."; error=1; }
    [ "${MACHINE[$server]}" ] && { err "Invalid configuration: MACHINE[$server]. The Administration Server must not be assigned to any machine."; error=1; }
  fi
done

# Check if managed servers are assigned to valid machines
for m in $(echo "${MACHINE[@]}"|tr ' ' '\n'|sort|uniq); do
  [ "${NM_LISTENADDRESS[$m]}" ] || { err "Missing configuration: NM_LISTENADDRESS[$m]"; error=1; }
done

# Check required commands that may not be installed
hash xpath 2>/dev/null || { err "Command xpath is required but not installed.  "; error=1; }
hash xml_grep 2>/dev/null || { err "Command xml_grep is required but not installed.  "; error=1; }
hash fuser 2>/dev/null || { err "Command fuser is required but not installed.  "; error=1; }
hash arping 2>/dev/null || { err "Command arping is required but not installed.  "; error=1; }

[ "$error" -ne 0 ] && exit 1
msg "All required configuration parameters are set - OK"

# Check installation user
if [ $(whoami) != "$WLS_OS_USER" ]; then
  err "The installer must be run as user $WLS_OS_USER instead of $(whoami)"
  exit 1 # exit right here when this check has failed
else
  msg "Installation user is $WLS_OS_USER - OK"
fi

rc=0

msg "Checking required external files in $SOFTWARE_REPO_PATH ..."
sha256sum --check <<EOF
212cb907ac2639598efe77511688776e5fcb1f89a668c40d3876fba595bb6109  $SOFTWARE_REPO_PATH/rolandhuss/jolokia.war
aaaaa3145f33a1f81c75925bd4c93a24b3a8f2bc439ecc7866cce5685b6f5698  $SOFTWARE_REPO_PATH/oracle/weblogic/wdt_3.2.5/weblogic-deploy.tar.gz
EOF
[ $? -ne 0 ] && exit 1

# Check if all configured listen addresses can be resolved
echo "${NM_LISTENADDRESS[@]}" "${LISTENADDRESS[@]}"|tr ' ' '\n'|sort|uniq|
{
  while read dn; do
    if [ "$(getIPForName $dn)" ]  2>&1 ; then
      msg "$dn can be resolved - OK"
    else
      err "$dn cannot be resoved by DNS or /etc/hosts"
      rc_inner=1
    fi
  done
  exit $rc_inner;
}
rc=$?


if [ "$HA_DOMAIN" == "true" -a "$ADMIN_FLIP_ENABLED" == "true" ]; then
  if ping -c 1 -W 3 ${LISTENADDRESS[$ADMINSERVER_NAME]} >/dev/null; then
    err "The admin server floating IP for ${LISTENADDRESS[$ADMINSERVER_NAME]} is available on the network. This address must be down before the installation is started."
    rc=1
  fi
fi

# Check sudo rules
if [ "$HA_DOMAIN" == "true" -a "$ADMIN_FLIP_ENABLED" == "true" ]; then
  sudo -n ip -V >/dev/null || { err "Missing permission to run 'sudo ip'"; rc=1; }
  sudo -n arping -V >/dev/null || { err "Missing permission to run 'sudo arping'"; rc=1; }
fi

# Check directories
if touch "$BASEDIR/dummy$$" && rm "$BASEDIR/dummy$$"; then
  msg "Directory $BASEDIR exists - OK"
else
  err "The directory $BASEDIR doesn't exist or has wrong permissions"
  rc=1
fi
if touch "$LOGDIR_PATH/dummy$$" && rm "$LOGDIR_PATH/dummy$$"; then
  msg "Directory $LOGDIR_PATH exists - OK"
else
  err "The directory $LOGDIR_PATH doesn't exist or has wrong permissions"
  rc=1
fi
if [ "$HA_DOMAIN" == "true" ] && [ "$SHAREDSTORAGE_PATH" ]; then
  if touch "$SHAREDSTORAGE_PATH/dummy$$" && rm "$SHAREDSTORAGE_PATH/dummy$$"; then
    msg "Directory $SHAREDSTORAGE_PATH exists - OK"
  else
    err "The directory $SHAREDSTORAGE_PATH doesn't exist or has wrong permissions"
    rc=1
  fi
fi


for remote_host in "${MACHINES[@]}"; do
  if [ "$(hostname)" != "$remote_host" ]; then
    # Check SSH trust
    if $(ssh -q -o BatchMode=yes "$remote_host" exit); then
      msg "Trusted SSH connection from $(hostname) to $remote_host - OK"
    else
      err "Trusted SSH connection from $(hostname) to $remote_host - FAILED"
      rc=1
    fi

    if [ $rc -eq 0 ]; then
      # Check if local and remote UID/GID are identical
      uidgid_local="$(id -u),$(id -g)"
      uidgid_remote="$(ssh -q -o BatchMode=yes "$remote_host" echo '$(id -u),$(id -g)')"
      if [ "$uidgid_local" == "$uidgid_remote" ]; then
        msg "UID and GID of user $(whoami) are identical on $(hostname) and $remote_host - OK"
      else
        err "UID,GID=$uidgid_local of user $(whoami) on $(hostname) do not match UID,GID=$uidgid_remote on $remote_host - FAILED"
        rc=1
      fi

      # Check system time difference
      clock_remote="$(ssh -q -o BatchMode=yes "$remote_host" date '+%s')"
      clock_local="$(date '+%s')"
      clock_diff=$(( clock_remote - clock_local ))
      if (( clock_diff < 5)) && (( clock_diff > -5 )); then
        msg "System clocks on $(hostname) and $remote_host are in sync - OK"
      else
        err "System clocks on $(hostname) and $remote_host are out of sync by $clock_diff seconds - FAILED"
        rc=1
      fi
    fi
  fi
done





if [ $rc -eq 0 ]; then
  msg "Prerequisites check passed"
else
  exit $rc
fi
