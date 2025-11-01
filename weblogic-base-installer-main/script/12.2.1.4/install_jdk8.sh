#!/bin/bash
#
# Install the JDK
# Created: 2016-10-11 dkovacs of virtual7

cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg  "Installing JDK ..."
rm -rf "$JAVA_HOME" &&
  mkdir -p "$(dirname $JAVA_HOME)" &&
  cd "$workdir/temp" &&
  tar -xzf "$SOFTWARE_REPO_PATH/oracle/java/jdk-8u381-linux-x64.tar.gz" &&
  mv jdk1.8.0_381 "$JAVA_HOME" ||
  exit 1