#!/bin/bash
#
# Create directories for filestores and application data
#
# Created: 2018-07-06 dkovacs of virtual7
#
# 2018-08-03  Adapted for using configuration arrays  (dkovacs)
cd "$(dirname $0)/.."; workdir="$(pwd)"
. $workdir/script/functions.sh

if [ -e "$ASERVER_HOME" ]; then
  if [ ! -L "$ASERVER_HOME" ]; then
    mkdir "$ASERVER_HOME/filestores"
  fi
fi