#!/bin/bash
#
# Enable the Unlimited Strength Java(TM) Cryptography Extension Policy Files
# Created: 2018-01-02 dkovacs of virtual7
cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Enabling the Unlimited Strength Java(TM) Cryptography Extension Policy Files ..."
# Uncomment "crypto.policy=unlimited" in $JAVA_HOME/jre/lib/security/java.security
bu "$JAVA_HOME/jre/lib/security/java.security" &&
  sed -i '/^#crypto.policy=unlimited/s/^#//' "$JAVA_HOME/jre/lib/security/java.security"
