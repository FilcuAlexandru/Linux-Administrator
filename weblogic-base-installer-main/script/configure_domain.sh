#!/bin/bash
#
# Only generic domain configuration is done here.
# Application specific confiuration will be done separately.
# Created: 2016-10-11 dkovacs of virtual7
#
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Staring $ADMINSERVER_NAME ..."
$ASERVER_HOME/custom_scripts/command-control.sh start $ADMINSERVER_NAME

# Credentials will be passed as env. vars to wlst
export WLS_ADMIN_USER
export WLS_ADMIN_PW

# Configure domain
msg "Applying configuration changes ..."
cat >$workdir/temp/configure_domain_1.py << EOF
# Get parameters from the environment
wlsAdminUser=os.environ['WLS_ADMIN_USER']
wlsAdminPw=os.environ['WLS_ADMIN_PW']

connect(wlsAdminUser, wlsAdminPw ,'t3://${LISTENADDRESS[$ADMINSERVER_NAME]}:${LISTENPORT[$ADMINSERVER_NAME]}')

edit()
startEdit()

EOF

for srv in "${SERVERS[@]}"; do
cat >>$workdir/temp/configure_domain_1.py << EOF
if '$srv' != '$ADMINSERVER_NAME':
    # Set IuK37 standard java options
    print('Setting Java options for $srv')
    cd('/Servers/$srv/ServerStart/$srv')
    if '$weblogic_version' == '12.2.1.4':
        cmo.setArguments("-Xloggc:servers/$srv/logs/gc.%t.log -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -Djavax.net.ssl.trustStore=$TRUST_STORE")
    else:
        cmo.setArguments("-Xlog:gc*:file=servers/$srv/logs/gc.%t.log -Djavax.net.ssl.trustStore=$TRUST_STORE")

# Configure SSL
if '$srv' == '$ADMINSERVER_NAME' or '$SSL_ONLY'.lower() == 'true':
    print('Disabling plain listen port on $srv')
    cd('/Servers/$srv')
    cmo.setListenPortEnabled(false)  # Disabling non-SSL port will take effect on next restart
if '$SSL_ONLY'.lower() == 'true':
    print('Setting default protocol to t3s on $srv')
    cd('/Servers/$srv')
    cmo.setDefaultProtocol('t3s')
EOF
done

for cl in $(echo "${CLUSTER[@]}"|tr ' ' '\n'|sort|uniq); do
cat >>$workdir/temp/configure_domain_1.py << EOF
if '$SSL_ONLY'.lower() == 'true':
    print('Enabling secure replication for cluster $cl')
    cd('/Clusters/$cl')
    cmo.setSecureReplicationEnabled(true)

# Set timeout for graceful shutdown
print('Set timeout for graceful shutdown on $srv')
cd('/Servers/$srv')
cmo.setGracefulShutdownTimeout(300)

EOF
done

cat >>$workdir/temp/configure_domain_1.py << EOF
# Turn off log rotation
print('Turning off log rotation')
cd('/Log/$DOMAIN_NAME')
cmo.setRotationType('none')

EOF

for srv in "${SERVERS[@]}"; do
cat >>$workdir/temp/configure_domain_1.py << EOF
print('Setting log date format for $srv')
cd('/Servers/$srv/Log/$srv')
cmo.setDateFormatPattern('yyyy-MM-dd HH:mm:ss.SSS')
print('Turning off log rotation for $srv')
cd('/Servers/$srv/Log/$srv')
cmo.setRotationType('none')
cd('/Servers/$srv/WebServer/$srv/WebServerLog/$srv')
cmo.setRotationType('none')
cd('/Servers/$srv/DataSource/$srv/DataSourceLogFile/$srv')
cmo.setRotationType('none')
print('Setting extended access log format for $srv')
cd('/Servers/$srv/WebServer/$srv/WebServerLog/$srv')
cmo.setLogFileFormat('extended')
cmo.setELFFields('date time time-taken cs(X-Forwarded-For) c-ip cs-method cs-uri sc-status bytes')

EOF
done

cat >>$workdir/temp/configure_domain_1.py << EOF
# Enable configuration archive and audit
print('Enabling configuration archive and audit')
cd('/')
cmo.setArchiveConfigurationCount(50)
cmo.setConfigBackupEnabled(true)
cmo.setConfigurationAuditType('log')

activate()
disconnect()
EOF

$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/temp/configure_domain_1.py


