#!/bin/bash
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

tarball_name="weblogic_base_installer_${wls_installer_version}.tgz"
find . -name "*.sh"|xargs chmod u+x
cd ..
topdir=$(basename $workdir)
tar -czf $topdir/build/$tarball_name \
    $topdir/config/install.conf \
    $topdir/script \
    $topdir/CHANGELOG.md \
    $topdir/install.sh \
    $topdir/README.md