#!/bin/bash
#
# Verify installation prerequisites.

cd "$(dirname $0)/../../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

# Check if configuration parameters are set
error=0
[ "$SOA_CLUSTER" ] || { err "Missing configuration: SOA_CLUSTER"; error=1; }
[[ " ${CLUSTER[@]} " =~ " $SOA_CLUSTER " ]] || { err "Invalid configuration: SOA_CLUSTER"; error=1; }
[ "$SOA_DB_CONNECT_STRING" ] || { err "Missing configuration: SOA_DB_CONNECT_STRING"; error=1; }
[ "$SOA_DBA_USER" ] || { err "Missing configuration: SOA_DBA_USER"; error=1; }
[ "$SOA_SCHEMA_PREFIX" ] || { err "Missing configuration: SOA_SCHEMA_PREFIX"; error=1; }

[ "$error" -ne 0 ] && exit 1
msg "All required configuration parameters are set - OK"

msg "Checking required external files in $SOFTWARE_REPO_PATH ..."
sha256sum --check <<EOF
76e7e9c765bead9ec1e9dd607885e828f0aea93b3c022c8c09d46fed8318aec4  $SOFTWARE_REPO_PATH/oracle/soa/12.2.1.4/install/fmw_12.2.1.4.0_soa.jar
a7803f4f01e24fc7c1f6801414b982366c229bfd6e4f9cf62af6ae8d3001b48a  $SOFTWARE_REPO_PATH/oracle/soa/12.2.1.4/patches/CPU_JUL2023/p35445981_122140_Generic.zip
EOF
[ $? -ne 0 ] && exit 1

# TODO - check database connection
# ...

msg "SOA prerequisites check passed"
