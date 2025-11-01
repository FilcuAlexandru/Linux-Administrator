#!/bin/bash
#
# Creates the template to be used later for creating managed server domain directories
# Created: 2018-05-07 dkovacs of virtual7
#
# 2018-08-03  Adapted for using configuration arrays  (dkovacs)
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

$ASERVER_HOME/custom_scripts/command-control.sh stop $ADMINSERVER_NAME

msg "Packing domain home $ASERVER_HOME ..."
rm -f "$workdir/temp/domain_packed.jar" &&
$ORACLE_HOME/oracle_common/common/bin/pack.sh -managed=true -domain=$ASERVER_HOME -template=$workdir/temp/domain_packed.jar -template_name=$DOMAIN_NAME &&

for machine in "${MACHINES[@]}"; do
  if [ "$machine" != "$(hostname)" ]; then
    msg "Copying domain template to host $machine ..."
    scp $workdir/temp/domain_packed.jar "$machine:$rworkdir/temp/" || exit 1
  fi
done
