#!/bin/bash
#
# Set rankeystore type to 
#
cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Changing java default keystore type from pkcs12 to jks"
sed -i '/^keystore.type/s/pkcs12/jks/' "$JAVA_HOME/conf/security/java.security"
