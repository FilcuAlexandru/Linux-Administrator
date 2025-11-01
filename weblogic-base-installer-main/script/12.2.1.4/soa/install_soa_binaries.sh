#!/bin/bash
#
# Install SOA binaries
# Created: 2020-09-11 dkovacs of virtual7

cd "$(dirname $0)/../../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Installing SOA Suite ${soa_version} binaries ..."
installer_jar="fmw_${soa_version}.0_soa.jar"

# Create response file
cat >$workdir/temp/soa_response <<EOF
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

#Set this variable value to the Installation Type selected. e.g. SOA Suite, BPM.
INSTALL_TYPE=SOA Suite


EOF

# Run the installer
$JAVA_HOME/bin/java -jar $SOFTWARE_REPO_PATH/oracle/soa/${soa_version}/install/$installer_jar -silent -responseFile $workdir/temp/soa_response -invPtrLoc $BASEDIR/product/oraInst.loc
