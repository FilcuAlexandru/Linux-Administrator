#!/bin/bash
#
# Install SOA Suite patches
# Created: 2020-09-11 dkovacs of virtual7
#
cd "$(dirname $0)/../../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

export PATH=$ORACLE_HOME/OPatch:$PATH
export ORACLE_HOME

msg "Installing Patch 35445981: SOA BUNDLE PATCH 12.2.1.4.230530"
cd $workdir/temp &&
  $JAVA_HOME/bin/jar -xf $SOFTWARE_REPO_PATH/oracle/soa/12.2.1.4/patches/CPU_JUL2023/p35445981_122140_Generic.zip &&
  cd $workdir/temp/35445981 &&
  opatch apply -silent ||
  exit 1