#!/bin/bash
#
# Show a summary message at the end of the installation.
# Created: 2016-10-11 dkovacs of virtual7
#
cd "$(dirname $0)/.."; export workdir="$(pwd)"
. $workdir/script/functions.sh


if [ "$ADMIN_CHANNEL_ENABLED" == "true" ]; then
  port=${ADMINPORT[$ADMINSERVER_NAME]}
else
  port=${SSLPORT[$ADMINSERVER_NAME]}
fi 
consoleUrl1="https://${LISTENADDRESS[$ADMINSERVER_NAME]}:$port/console"
consoleUrl2="https://$(getIPForName ${LISTENADDRESS[$ADMINSERVER_NAME]}):$port/console"



# Show the installation summary
cat <<EOF
======================
Installation completed
======================
Version:             $weblogic_version
JAVA_HOME:           $JAVA_HOME
DOMAIN_HOME:         $ASERVER_HOME
Start/stop scripts:  $ASERVER_HOME/custom_scripts
WLS Console:         $consoleUrl1
                     $consoleUrl2


You still need to take care of the following:
==============================================

Additional WLS users
--------------------
Create additional WebLogic accouts as required (e.g. personal admin accounts).


Add WebLogic as system service
------------------------------
Run the below script as root on ${MACHINES[@]}

    /tmp/runAsRoot-$DOMAIN_NAME.sh


Log rotation
------------
Log rotation in WebLogic is disabled according to IuK37 standards. Make sure that
external log rotation is set up to cover all WLS and application logs.


Monitoring
----------
Integrate WebLogic with Monitoring


TLS Certificates
----------------
Request signed certificates using the CSRs below and then replace the existing self signed
certificates.
$(ls $(dirname "$ID_STORE")/*.csr)

EOF
