#!/bin/bash
#
# Verify installation prerequisites.

cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Checking installation prerequisites ..."

# Check configuration parameters
error=0
[ "$WLS_INSTALL_TYPE" == "generic-14c" ] || { err "Installer type \"$WLS_INSTALL_TYPE\" is not supported for WebLogic $weblogic_version"; error=1; }
[ "$error" -ne 0 ] && exit 1


msg "Checking required external files in $SOFTWARE_REPO_PATH ..."
sha256sum --check <<EOF
b4eb49c123e2cf2ed7cb068a37b84eb75fcf1e76c3620d3378f5735e11a8508b  $SOFTWARE_REPO_PATH/oracle/java/jdk-11.0.20_linux-x64_bin.tar.gz
5b0d998c39568f3231bc418f1a5a780afe11845ac2863afd280e193e2377b1ee  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_14.1.1.0/install/fmw_14.1.1.0.0_wls_lite_generic.jar
b967165cf6b84f477f890b13abc0686a21ced9baae3fc028c0e75322e4b79c3f  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_14.1.1.0/patches/CPU_JUL2023/p35679626_141100_Generic.zip
EOF
[ $? -ne 0 ] && exit 1

msg "Prerequisites check passed"
