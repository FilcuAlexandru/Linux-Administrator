#!/bin/bash
#
# Creates the Managed Server domain directory
# Created: 2018-07-15 dkovacs of virtual7
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

rm -rf "$MSERVER_HOME"
msg "Creating managed server domain home at $MSERVER_HOME ..."
$ORACLE_HOME/oracle_common/common/bin/unpack.sh -domain="$MSERVER_HOME" -template=$workdir/temp/domain_packed.jar
rc=$?
rm -rf "$ORACLE_HOME/user_projects" # clean up directoy created by unpack (bug?)
exit $rc