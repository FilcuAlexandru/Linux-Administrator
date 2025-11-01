#!/bin/bash
#
# Configure the Nodemanager
# Created: 2016-10-11 dkovacs of virtual7
#
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Configuring the node manager ..."
NM_HOME="$MSERVER_HOME/nodemanager"

# Create nodemanager.properties
msg "Creating $NM_HOME/nodemanager.properties"
mkdir -p "$NM_HOME" &&
cat >"$NM_HOME/nodemanager.properties" <<EOF
DomainsFile=$NM_HOME/nodemanager.domains
LogLimit=0
PropertiesVersion=12.2.1
AuthenticationEnabled=true
NodeManagerHome=$NM_HOME
JavaHome=$JAVA_HOME
LogLevel=INFO
DomainsFileEnabled=true
ListenAddress=${NM_LISTENADDRESS[$(hostname)]}
NativeVersionEnabled=true
ListenPort=$NM_PORT
LogToStderr=true
weblogic.StartScriptName=startWebLogic.sh
SecureListener=true
LogCount=1
QuitEnabled=false
LogAppend=true
weblogic.StopScriptEnabled=false
StateCheckInterval=500
CrashRecoveryEnabled=false
weblogic.StartScriptEnabled=true
LogFile=$NM_HOME/nodemanager.log
LogFormatter=weblogic.nodemanager.server.LogFormatter
ListenBacklog=50
KeyStores=CustomIdentityAndCustomTrust
CustomIdentityKeyStorePassPhrase=$KEYSTOREPASS
CustomIdentityPrivateKeyPassPhrase=$KEYSTOREPASS
CustomIdentityKeyStoreFileName=$ID_STORE
CustomIdentityKeyStoreType=jks
CustomIdentityAlias=${NM_LISTENADDRESS[$(hostname)]}
EOF
