#!/bin/bash
#
# Install WebLogic Deploy Tooling

cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg  "Installing WDT ..."
rm -rf "$WDT_HOME" &&
  mkdir -p "$(dirname $WDT_HOME)" &&
  cd "$workdir/temp" &&
  tar -xzf "$SOFTWARE_REPO_PATH/oracle/weblogic/wdt_3.2.5/weblogic-deploy.tar.gz" &&
  mv weblogic-deploy "$WDT_HOME" ||
  exit 1