#!/bin/bash
#
# Verify installation prerequisites.

cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Checking required external files in $SOFTWARE_REPO_PATH ..."
sha256sum --check <<EOF
bfcbb0b2832d42c8aedba5cc6a505cd8a455bc476767d210f5e9bdab772408fd  $SOFTWARE_REPO_PATH/oracle/java/jdk-8u381-linux-x64.tar.gz
e3259a905084a119e66073fc56807e8b0a54591b6256fbb8e80952b7565fc7f8  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/install/fmw_${weblogic_version}.0_infrastructure.jar
84570f047ac95eed7f101353c05b1c1b6b6313fc322925d4ae69cca1900da276  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/install/fmw_${weblogic_version}.0_wls.jar
5e7953516a8b2f16fbab232cdee5f52cb4d34747590884c3ff8af9d6b0c8a3fd  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p33950717_122140_Generic.zip
a8162dc0bf94bea426f2357255554f5eaedc9b905fac7948acc5d846328c3b85  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p34065178_122140_Generic.zip
53019f452d89b2b321b4b06d4eb7e2ca3db3b138e23e2e0d71520c74f03090fd  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p34542329_122140_Generic.zip
5e326331b152765f84764f99279e668705a7a8cc3dd1f3a3f17be5a0d9ecf9d7  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p34809489_122140_Generic.zip
00d837a98eab57426249be7c4d8f7f4ffcc7a1286fc2da3f8b103c1bcb64d9e8  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p35159582_122140_Generic.zip
258e79bb8680ce91d505e430171179593ef43f16e75e2d30dc791f4a43a6926b  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p35432543_122140_Generic.zip
97e16a6e5a3757cdc9e8e7c3e9bc22296dd9428722c784494b19bd874ab0949c  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p35503128_122140_Generic.zip
f9d7c016616e4a92dea2674428ddadc8506ae05981158ccda88d452690fd22ec  $SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023/p35679623_122140_Generic.zip
EOF
[ $? -ne 0 ] && exit 1


msg "Prerequisites check passed"
