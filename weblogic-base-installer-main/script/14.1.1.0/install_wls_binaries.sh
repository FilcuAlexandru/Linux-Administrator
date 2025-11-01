#!/bin/bash
#
# Install WebLogic binaries
# Created: 2016-10-11 dkovacs of virtual7
#
cd "$(dirname $0)/../.."; workdir="$(pwd)"
. $workdir/script/functions.sh


msg "Installing WebLogic ${weblogic_version} binaries using the generic installer ..."
installer_jar="fmw_${weblogic_version}.0_wls_lite_generic.jar"
install_type="WebLogic Server"


mkdir -p "$BASEDIR/product"
if [ -e "$ORACLE_HOME" ]; then
  rm -rf $ORACLE_HOME $BASEDIR/product/oraInventory
fi

# Create response file
cat >$workdir/temp/response <<EOF
[ENGINE]

#DO NOT CHANGE THIS.
Response File Version=1.0.0.0.0

[GENERIC]

#Set this to true if you wish to skip software updates
DECLINE_AUTO_UPDATES=true

#My Oracle Support User Name
MOS_USERNAME=

#My Oracle Support Password
MOS_PASSWORD=<SECURE VALUE>

#If the Software updates are already downloaded and available on your local system, then specify the path to the directory where these patches are available and set SPECIFY_DOWNLOAD_LOCATION to true
AUTO_UPDATES_LOCATION=

#Proxy Server Name to connect to My Oracle Support
SOFTWARE_UPDATES_PROXY_SERVER=

#Proxy Server Port
SOFTWARE_UPDATES_PROXY_PORT=

#Proxy Server Username
SOFTWARE_UPDATES_PROXY_USER=

#Proxy Server Password
SOFTWARE_UPDATES_PROXY_PASSWORD=<SECURE VALUE>

#The oracle home location. This can be an existing Oracle Home or a new Oracle Home
ORACLE_HOME=$ORACLE_HOME

#The federated oracle home locations. This should be an existing Oracle Home. Multiple values can be provided as comma seperated values
FEDERATED_ORACLE_HOMES=

#Set this variable value to the Installation Type selected. e.g. Fusion Middleware Infrastructure With Examples, Fusion Middleware Infrastructure.
INSTALL_TYPE=$install_type

EOF

# Create temporary inventory pointer file
cat >$BASEDIR/product/oraInst.loc <<EOF
inventory_loc=$BASEDIR/product/oraInventory
inst_group=$(id -gn)
EOF

# Run the installer
$JAVA_HOME/bin/java -jar $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/install/$installer_jar -silent -responseFile $workdir/temp/response -invPtrLoc $BASEDIR/product/oraInst.loc
