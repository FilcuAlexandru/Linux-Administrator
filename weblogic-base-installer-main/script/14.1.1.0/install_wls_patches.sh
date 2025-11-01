#!/bin/bash
#
# Install WebLogic patches
# Created: 2016-10-11 dkovacs of virtual7
#

cd "$(dirname $0)/../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

export PATH=$ORACLE_HOME/OPatch:$PATH
export ORACLE_HOME
tempdir="$workdir/temp"
PATCH_DIR_PATH="$SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023"

msg "*** JUL-2023 Critical Patch Update for WebLogic Server ${weblogic_version} ***"
msg "Installing Patch 35679626: WLS STACK PATCH BUNDLE 14.1.1.0.230806"
cd $tempdir &&
  unzip -q $PATCH_DIR_PATH/p35679626_141100_Generic.zip &&
  cd WLS_SPB_*/tools/spbat/generic/SPBAT &&
  ./spbat.sh -phase apply -oracle_home $ORACLE_HOME ||
  exit 1

msg "All patches installed successfully"
