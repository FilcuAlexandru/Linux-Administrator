#!/bin/bash
#
# Create a new WLS Domain for SOA
# Domain topology and minimum setting are configured here.
# Remaining settings are configured later in online mode.

cd "$(dirname $0)/../../.."; workdir="$(pwd)"
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

msg('Loading templates ...')
selectTemplate('Basic WebLogic Server Domain')
selectCustomTemplate('$ORACLE_HOME/oracle_common/common/templates/wls/oracle.jrf_template.jar')
selectCustomTemplate('$ORACLE_HOME/oracle_common/common/templates/wls/oracle.wsmpm_template.jar')
selectCustomTemplate('$ORACLE_HOME/oracle_common/common/templates/wls/oracle.ums_template.jar')
selectCustomTemplate('$ORACLE_HOME/em/common/templates/wls/oracle.em_wls_template.jar')
selectCustomTemplate('$ORACLE_HOME/soa/common/templates/wls/oracle.soa.refconfig_template.jar')
loadTemplates()

setOption('AppDir', '$APPLICATION_HOME')

# TODO - duplicate code -> remove
# msg('Setting administration server name')
# cd('Servers/AdminServer')
# cmo.setName('$ADMINSERVER_NAME')

msg('Setting administrator password')
cd('/Security/base_domain/User/weblogic')
cmo.setPassword('$WLS_ADMIN_PW')

msg('Setting production mode')
setOption('ServerStartMode','prod')

cd("/")
for server in cmo.getServers():
    if server.getName() != "$ADMINSERVER_NAME":
        msg ("Removing template managed server " + server.getName())
        delete(server.getName(), 'Server')

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

if '${CLUSTER[$srv]}' == '$SOA_CLUSTER':
    msg("Assigning server groups to  SOA Server $srv")
    setServerGroups('$srv', [ 'JRF-MAN-SVR', 'WSMPM-MAN-SVR', 'SOA-MGD-SVRS' ])

EOF
done

cat >>$workdir/temp/create_domain.py <<EOF
msg("Set WLS cluster $SOA_CLUSTER as target of defaultCoherenceCluster")
cd('/CoherenceClusterSystemResource/defaultCoherenceCluster')
set('Target', '$SOA_CLUSTER')

msg('Configuring the Service Table DataSource ...')
fmwDb = 'jdbc:oracle:thin:@$SOA_DB_CONNECT_STRING'
cd('/JDBCSystemResource/LocalSvcTblDataSource/JdbcResource/LocalSvcTblDataSource')
cd('JDBCDriverParams/NO_NAME_0')
set('DriverName', 'oracle.jdbc.OracleDriver')
set('URL', fmwDb)
set('PasswordEncrypted', '$SOA_SCHEMA_PW')

stbUser = '${SOA_SCHEMA_PREFIX}_STB'
cd('Properties/NO_NAME_0/Property/user')
set('Value', stbUser)

msg('Getting Database Defaults...')
getDatabaseDefaults()

msg('Writing new domain to $ASERVER_HOME')
writeDomain('$ASERVER_HOME')
closeTemplate()
exit()
EOF

$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/temp/create_domain.py
