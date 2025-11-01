#!/bin/bash
#
# Install WebLogic patches
# Created: 2016-10-11 dkovacs of virtual7
#

cd "$(dirname $0)/../.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

export PATH=$ORACLE_HOME/OPatch:$PATH
export ORACLE_HOME
tempdir="$workdir/temp"
PATCH_DIR_PATH="$SOFTWARE_REPO_PATH/oracle/weblogic/wls_${weblogic_version}/patches/CPU_JUL2023"

msg "*** JUL-2023 Critical Patch Update for WebLogic Server 12.2.1.4 ***"
if [ "$weblogic_installer" == "infrastructure" ]; then
    msg "Installing Required FMW Infrastructure Compatibility Patch for JDK 8 u331 (or later)"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p34065178_122140_Generic.zip &&
      cd $tempdir/34065178 &&
      opatch apply -silent ||
      exit 1
fi

msg "Installing Patch 35679623: WLS STACK PATCH BUNDLE 12.2.1.4.230806"
cd $tempdir &&
  unzip -q $PATCH_DIR_PATH/p35679623_122140_Generic.zip &&
  cd WLS_SPB_*/tools/spbat/generic/SPBAT &&
  ./spbat.sh -phase apply -oracle_home $ORACLE_HOME ||
  exit 1

if [ "$weblogic_installer" == "infrastructure" ]; then
    msg "*** JUL-2023 Critical Patch Update for FMW Infrastructure 12.2.1.4 ***"

    msg "Installing Patch 35503128: ADF BUNDLE PATCH 12.2.1.4.230615"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p35503128_122140_Generic.zip &&
      cd $tempdir/35503128 &&
      opatch apply -silent ||
      exit 1

    msg "Installing Patch 34809489: PS4 : CVE-2021-42575 IN ADF.ORACLE.DOMAIN.WEBAPP.WAR:WEB-INF/LIB/OWASP-JAVA-HTML-SANITIZER-20190325.1.JAR"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p34809489_122140_Generic.zip &&
      cd $tempdir/34809489 &&
      opatch apply -silent ||
      exit 1

    msg "Installing Patch 35159582: OWSM BUNDLE PATCH 12.2.1.4.230308"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p35159582_122140_Generic.zip &&
      cd $tempdir/35159582 &&
      opatch apply -silent ||
      exit 1

    msg "Installing Patch 34542329: MERGE REQUEST ON TOP OF 12.2.1.4.0 FOR BUGS 34280277 26354548 26629487 29762601"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p34542329_122140_Generic.zip &&
      cd $tempdir/34542329 &&
      opatch apply -silent ||
      exit 1

    msg "Installing Patch 33950717: OPSS BUNDLE PATCH 12.2.1.4.220311"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p33950717_122140_Generic.zip &&
      cd $tempdir/33950717 &&
      opatch apply -silent ||
      exit 1
	
    msg "installing Patch 35432543: WebCenter Core Bundle Patch 12.2.1.4.230525"
    cd $tempdir &&
      $JAVA_HOME/bin/jar -xf $PATCH_DIR_PATH/p35432543_122140_Generic.zip &&
      cd $tempdir/35432543 &&
      opatch apply -silent ||
      exit 1
fi
msg "All patches installed successfully"
