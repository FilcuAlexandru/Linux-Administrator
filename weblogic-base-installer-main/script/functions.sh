# Common fuction definitions and environent settings
# Created: 2016-10-11 dkovacs of virtual7

[ "$wls_installer_version" ] && return

wls_installer_version="2.3"
umask 027
export LANG=en_US.utf-8

# Configuration parameters that will be treated as associative arrays
declare -A NM_LISTENADDRESS LISTENPORT SSLPORT ADMINPORT LISTENADDRESS MACHINE CLUSTER

# Source configuration parameters
. $workdir/config/install.conf

# Set derived parameters
case "$WLS_INSTALL_TYPE" in
  generic-12c)
    weblogic_version="12.2.1.4"
    weblogic_installer="generic"
    fmw_product=""
    ;;
  infrastructure-12c)
    weblogic_version="12.2.1.4"
    weblogic_installer="infrastructure"
    fmw_product=""
    ;;
  soa-12c)
    weblogic_version="12.2.1.4"
    weblogic_installer="infrastructure"
    fmw_product="soa"
    ;;
  generic-14c)
    weblogic_version="14.1.1.0"
    weblogic_installer="generic"
    fmw_product=""
    ;;
  *)
    weblogic_version="_invalid_"
    weblogic_installer="_invalid_"
    fmw_product="_invalid_"
    ;;
esac
BASEDIR="/$WLS_OS_USER"  # Top-level installation directory
JAVA_HOME="$BASEDIR/product/jdk"
ORACLE_HOME="$BASEDIR/product/fmw_${weblogic_version}"
ASERVER_HOME="$BASEDIR/domains/aserver/$DOMAIN_NAME" # Administration Server domain home installed on shared disk
MSERVER_HOME="$BASEDIR/domains/mserver/$DOMAIN_NAME" # Managed Server domain home installed on local disk
APPLICATION_HOME="$BASEDIR/applications/$DOMAIN_NAME" # Application home directory installed on shared disk
MACHINES=("${!NM_LISTENADDRESS[@]}") # list of machines - all keys from NM_LISTENADDRESS
SERVERS=("${!LISTENADDRESS[@]}")  # # list of servers - all keys from LISTENADDRESS
if [ "${#MACHINES[@]}" -gt 1 ]; then
  HA_DOMAIN=true
else
  HA_DOMAIN=false
fi
ID_STORE=$ASERVER_HOME/keystores/identity.jks
TRUST_STORE=$ASERVER_HOME/keystores/trust.jks
WDT_HOME="$BASEDIR/product/weblogic-deploy"

# Set default parameters
WLS_ADMIN_USER=weblogic # Default administrator. Do not change!
ASERVER_START_TIMEOUT=120 # Default timeout for starting the administration server
ASERVER_MEMORY="-Xms512m -Xmx1024m" # Administration server memory args
JAVA_USE_NONBLOCKING_PRNG="true" # use /dev/urandom instead of /dev/random as random number source for better performance
SSL_ONLY="true" # true -> disable plain listen port on managed servers


# Message to stdout and log file
msg() {
  echo -e "[$(date +'%Y-%m-%dT%H:%M:%S')] [$(hostname)] [$(basename $0)] $1"|tee -a $workdir/log/install.log
}

# Message to stderr and log file
err() {
  msg "ERROR: $@" >&2
}

# Exit if this host is not $1
exitIfHostIsNot() {
  if [ "$(hostname)" != "$1" ]; then
    err "This script is not supposed to run on host $(hostname). Exiting."
    exit 1
  fi
}

# Backup a file or directory
#
# Arguments:
#  $1: The file to be backed up
# Returns:
#  0=success|1=error
bu() {
  buname="$1.$(date '+%Y%m%d')"
  if [ -e "$buname" ]; then
    echo "Cannot backup $1. $buname already exists." >&2
    return 1
  else
    cp -rp "$1" "$buname"
  fi
}


canskip() {
  # Initialize step counters if not done yet
  [ "$stepcount" ] || stepcount=0
  [ "$startstep" ] || startstep=99999
  [ "$endstep" ] || endstep=99998
  
  stepcount=$((stepcount+1))
  # Step can be skipped if current stepcount is not between start- and end step numbers
  [ $stepcount -lt $startstep -o $stepcount -gt $endstep ]
}

# Execute or skip command $1 on host $2
# depending on start/endstep numbers
dostep() {
  command="$1"
  host="$2"
  [ "$host" ] || host="$(hostname)" # default to current host
  
  if canskip; then
    msg "[SKIPPED #$stepcount] [$host:$command]"
  else
    msg "[EXECUTE #$stepcount] [$host:$command]"
    
    if [ "$host" == "$(hostname)" ]; then
      # execute local command
      eval "$command" 2>&1|tee -a $workdir/log/install.log #execute and log output
    else
      # execute remote command
      exports="export KEYSTOREPASS=$KEYSTOREPASS" # env. variables to be made available on the remote side
      ssh $host "${exports};cd $rworkdir;eval \"${command}\"" 2>&1|tee -a $workdir/log/install.log #execute and log output
    fi
    rc=${PIPESTATUS[0]}
    if [ "$rc" -ne 0 ]; then
      msg "[FAILED  #$stepcount] [$command on $host]"
      step_rc="$rc"
      endstep=0 # subsequent steps will be skipped
    fi
    return $rc
  fi
}

# Read a password from the command line
readpasswd() {
pass=""
pwd1=x;pwd2=y
while [ "$pwd1" != "$pwd2" ]; do
  echo "Enter password:"; stty -echo; read pwd1; stty echo
  echo "Retype password:"; stty -echo; read pwd2; stty echo
  if [ "$pwd1" != "$pwd2" ]; then
    echo "Passwords don't match."
  fi
done
pass="$pwd1"
}

# Look up the IP for the specified name in DNS or /etc/hosts
getIPForName () {
  ( host "$1" || getent ahostsv4 "$1" ) | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | head -1
}

if [ "$weblogic_version" != "_invalid_" ]; then
  . $workdir/script/$weblogic_version/$fmw_product/functions.sh
fi
