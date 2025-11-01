#!/bin/bash
#
# Install the JDK
# Created: 2016-10-11 dkovacs of virtual7
#
cd "$(dirname $0)/../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg  "Installing JDK ..."
rm -rf "$JAVA_HOME" &&
  mkdir -p "$(dirname $JAVA_HOME)" &&
  cd "$workdir/temp" &&
  tar -xzf "$SOFTWARE_REPO_PATH/oracle/java/jdk-11.0.20_linux-x64_bin.tar.gz" &&
  mv jdk-11.0.20 "$JAVA_HOME" ||
  exit 1