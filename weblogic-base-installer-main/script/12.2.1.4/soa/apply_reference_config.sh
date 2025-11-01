#!/bin/bash
#
# Apply SOA reference configuration
# See https://docs.oracle.com/en/middleware/fusion-middleware/12.2.1.4/insoa/configuring-product-domain.html#GUID-5A5684F6-4CED-40DB-8606-DBA489920FAC
# Created: 2020-09-11 dkovacs of virtual7

cd "$(dirname $0)/../../.."; workdir="$(pwd)"
. $workdir/script/functions.sh

# soaWLSParams.silent.py is funtcionally identical to soaWLSParams.py from Oracle but
# adapted for non-interactive use
cp $workdir/script/${weblogic_version}/soa/soaWLSParams.silent.py $ORACLE_HOME/soa/common/tools/refconfig/

msg "Staring SOA Servers ..."
$ASERVER_HOME/custom_scripts/command-control.sh nmstart all &&
    $ASERVER_HOME/custom_scripts/command-control.sh start $ADMINSERVER_NAME $SOA_CLUSTER || exit 1

msg "Applying SOA reference configuration ... "
export WLS_ADMIN_PW
cd $ORACLE_HOME/soa/common/tools/refconfig &&
    $ORACLE_HOME/oracle_common/common/bin/wlst.sh soaWLSParams.silent.py \
        -domain $DOMAIN_NAME \
        -user $WLS_ADMIN_USER \
        -adminhost ${LISTENADDRESS[$ADMINSERVER_NAME]} \
        -adminport ${LISTENPORT[$ADMINSERVER_NAME]} 
