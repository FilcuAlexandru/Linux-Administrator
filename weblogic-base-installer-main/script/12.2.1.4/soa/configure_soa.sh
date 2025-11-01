#!/bin/bash
#
# Configure SOA settings in WLST online mode
# Created: 2020-09-11 dkovacs of virtual7

cd "$(dirname $0)/../../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Staring $ADMINSERVER_NAME ..."
$ASERVER_HOME/custom_scripts/command-control.sh start $ADMINSERVER_NAME

msg "Configuring SOA ..."
export WLS_ADMIN_USER
export WLS_ADMIN_PW
admin_url='t3://${LISTENADDRESS[$ADMINSERVER_NAME]}:${LISTENPORT[$ADMINSERVER_NAME]}'
$ORACLE_HOME/oracle_common/common/bin/wlst.sh $workdir/script/${weblogic_version}/soa/configure_soa.py \
    -adminUrl "t3://${LISTENADDRESS[$ADMINSERVER_NAME]}:${LISTENPORT[$ADMINSERVER_NAME]}" \
    -soaCluster "$SOA_CLUSTER" \
    -sharedStoragePath "$SHAREDSTORAGE_PATH"
