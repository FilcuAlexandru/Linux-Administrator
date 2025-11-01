#!/bin/bash
#
# Create a new WLS Domain
# Domain topology and minimum setting are configured here.
# Remaining settings are configured later in online mode.
#
# Created: 2016-09-05 dkovacs of virtual7

cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Creating new WLS domain ..."
rm -rf "$ASERVER_HOME" "$APPLICATION_HOME" &&
  mkdir -p "$ASERVER_HOME" "$APPLICATION_HOME"

cat >$workdir/temp/create_domain.py <<EOF
import time as systime
import os
import socket as sck

def msg(message):
    tstamp = systime.strftime("%Y-%m-%dT%H:%M:%S", systime.localtime())
    host = sck.gethostname()
    scriptname = os.path.basename(sys.argv[0])
    print("[%s] [%s] [%s] [%s]" % (tstamp, host, scriptname, message))

msg('Loading domain template')
selectTemplate('Basic WebLogic Server Domain')
loadTemplates()

setOption('AppDir', '$APPLICATION_HOME')

print('Setting administrator password')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('$WLS_ADMIN_PW')

print('Setting production mode')
setOption('ServerStartMode','prod')

EOF

for mcn in "${MACHINES[@]}"; do
cat >>$workdir/temp/create_domain.py <<EOF
# Create machine $mcn
msg('Creating Machine $mcn')
cd('/')
machine=create('$mcn', 'Machine')
cd('Machine/$mcn')
create('$mcn', 'NodeManager')
cd('NodeManager/$mcn')
set('ListenAddress', '${NM_LISTENADDRESS[$mcn]}')
set('ListenPort', int('$NM_PORT'))
set('NMType', 'SSL')
set('NodeManagerHome', '$NM_HOME')
EOF
done

for cl in $(echo "${CLUSTER[@]}"|tr ' ' '\n'|sort|uniq); do
cat >>$workdir/temp/create_domain.py <<EOF
# Create cluster $cl
msg('Creating Cluster $cl')
cd('/')
create('$cl', 'Cluster')
EOF
done

for srv in "${SERVERS[@]}"; do
cat >>$workdir/temp/create_domain.py <<EOF
if '$srv' != '$ADMINSERVER_NAME':
    # Create managed server $srv
    msg('Creating managed server $srv')
    cd("/")
    create('$srv', 'Server')
    cd('Server/$srv')
    set('Machine', '${MACHINE[$srv]}')
    if '${CLUSTER[$srv]}':
        set('Cluster', '${CLUSTER[$srv]}')
else:
    msg('Setting admin server name: $ADMINSERVER_NAME')
    cd('/Server/AdminServer')
    set('Name', '$ADMINSERVER_NAME')

msg("Setting listen address and ports for $srv")
cd('/Server/$srv')
set('ListenAddress', '${LISTENADDRESS[$srv]}')
set('ListenPort', int('${LISTENPORT[$srv]}'))
set('AdministrationPort', int('${ADMINPORT[$srv]}'))
create('$srv','SSL')
cd('SSL/$srv')
set('Enabled', 'true')
set('ListenPort', int('${SSLPORT[$srv]}'))

msg("Configuring SSL for $srv")
cd('/Server/$srv')
set('KeyStores', 'CustomIdentityAndCustomTrust')
set('CustomIdentityKeyStoreFileName', '$ID_STORE')
set('CustomIdentityKeyStoreType', 'jks')
set('CustomIdentityKeyStorePassPhraseEncrypted', '$KEYSTOREPASS')
set('CustomTrustKeyStoreFileName', '$TRUST_STORE')
set('CustomTrustKeyStoreType', 'jks')
set('CustomTrustKeyStorePassPhraseEncrypted', '$TRUSTSTOREPASS')
cd('SSL/$srv')
set('ServerPrivateKeyAlias', '${LISTENADDRESS[$srv]}')
set('ServerPrivateKeyPassPhraseEncrypted', '$KEYSTOREPASS')

EOF
done

cat >>$workdir/temp/create_domain.py <<EOF
msg('Writing new domain to $ASERVER_HOME')
writeDomain('$ASERVER_HOME')
closeTemplate()
exit()
EOF

$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/temp/create_domain.py
