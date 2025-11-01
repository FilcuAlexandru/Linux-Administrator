#!/bin/bash
#
# Start the AdminServer and prepa
# boot.properties, operator account and UserConfig files
# 
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

# Temporary boot.properties with admin credentials
mkdir -p $ASERVER_HOME/servers/AdminServer/security
cat >$ASERVER_HOME/servers/AdminServer/security/boot.properties << EOF
password=$WLS_ADMIN_PW
username=$WLS_ADMIN_USER
EOF

msg "Staring $ADMINSERVER_NAME ..."
$ASERVER_HOME/custom_scripts/command-control.sh start $ADMINSERVER_NAME

# Credentials will be passed as env. vars to wlst
export WLS_ADMIN_USER
export WLS_ADMIN_PW
export WLS_OPERATOR_USER
export WLS_OPERATOR_PW

msg "Creating operator user ..."
cat >$workdir/temp/configure_domain_1.py << EOF
# Get parameters from the environment
wlsAdminUser=os.environ['WLS_ADMIN_USER']
wlsAdminPw=os.environ['WLS_ADMIN_PW']
wlsOperatorUser=os.environ['WLS_OPERATOR_USER']
wlsOperatorPw=os.environ['WLS_OPERATOR_PW']

connect(wlsAdminUser, wlsAdminPw ,'t3://${LISTENADDRESS[$ADMINSERVER_NAME]}:${LISTENPORT[$ADMINSERVER_NAME]}')

# Creating operator user
cd('serverConfig:/SecurityConfiguration/$DOMAIN_NAME/Realms/myrealm/AuthenticationProviders/DefaultAuthenticator')
cmo.createUser(wlsOperatorUser,wlsOperatorPw,'Operator')
cmo.addMemberToGroup('operators',wlsOperatorUser)
disconnect()
EOF
$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/temp/configure_domain_1.py || exit 1

# Create userConfig and userKey files as operator
msg "Creating userConfig and userKey for operator user authentication ..." 
cat >$workdir/temp/storeOperatorCredentials.py <<EOF
# Get parameters from the environment
operatorUser=os.environ['WLS_OPERATOR_USER']
operatorPw=os.environ['WLS_OPERATOR_PW']
scriptdir = '$ASERVER_HOME/custom_scripts'
connect(operatorUser, operatorPw ,'t3://${LISTENADDRESS[$ADMINSERVER_NAME]}:${LISTENPORT[$ADMINSERVER_NAME]}')
storeUserConfig(scriptdir + '/userConfig', scriptdir + '/userKey')
disconnect()
EOF
$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/temp/storeOperatorCredentials.py
rc=$?
chmod 600 $ASERVER_HOME/custom_scripts/userConfig $ASERVER_HOME/custom_scripts/userKey

# Install final boot.properties with operator credentials
cat >$ASERVER_HOME/servers/AdminServer/security/boot.properties << EOF
password=$WLS_OPERATOR_PW
username=$WLS_OPERATOR_USER
EOF

msg "Stopping $ADMINSERVER_NAME ..."
$ASERVER_HOME/custom_scripts/command-control.sh stop $ADMINSERVER_NAME
exit $rc
