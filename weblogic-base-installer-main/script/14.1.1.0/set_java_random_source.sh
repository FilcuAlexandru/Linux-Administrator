#!/bin/bash
#
# Set random source to /dev/urandom
# Created: 2020-07-17 dkovacs of virtual7
#
cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Changing java random number source from /dev/random to /dev/urandom"
sed -i '/^securerandom.source/s/\/dev\/random/\/dev\/urandom/' "$JAVA_HOME/conf/security/java.security"
