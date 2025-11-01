#!/bin/bash
#
# Install and configure a WebLogic domain according to IuK37 conventions.
# The resulted WebLogic domain is ready to be used for application deployments.
#
# This is the main script to start the installation.
#
# Usage: install.sh [startstep-number] [endstep-number]
#        No arguments:      Installation steps will only be listed but not executed.
#        startstep-number:  the first step to execute
#        endstep-number:    the last step to execute
#
# Tested for WebLogic 12.2.1.4 on SLES 12 SP4 and SLES 15 SP4
# Created: 2019-12-11 D.Kovacs of virtual7

cd "$(dirname $0)"
export workdir="$(pwd)"

mkdir -p $workdir/temp $workdir/log

# TODO - remove support for extensions?
# Delete any previously installed extension directories
# find script -mindepth 1 -type d |xargs rm -rf

## Install extensions
#for ext_tarball in $(find extensions -name "extension_*.tgz"); do
#  tar --skip-old-files -xzf $ext_tarball
#done

# Source functions and configuration parameters
. $workdir/script/functions.sh

# Verify weblogic_version
if [ "$weblogic_version" == "_invalid_" ]; then
  err "Missing or invalid configuration: WLS_INSTALL_TYPE"
  exit 1
fi

# Set startstep and endstep from the command-line arguments and check them for being valid integers.
if [ $# -gt 0 ]; then
  startstep="$1"
  if [[ ! $startstep =~ ^-?[0-9]+$ ]]; then
    err "Invalid parameter: $startstep"
    exit 1
  fi
fi
if [ $# -gt 1 ]; then
  endstep="$2"
  if [[ ! $endstep =~ ^-?[0-9]+$ ]]; then
    err "Invalid parameter: $endstep"
    exit 1
  fi
fi

if [ "$1" ]; then
  #msg "Installation started with the following configuration:\n$(cat $workdir/config/*.conf)\nstartstep=$startstep endstep=$endstep"
  # Source prompt_password.sh files
  source $workdir/script/prompt_passwords.sh
  if [ -f $workdir/script/${weblogic_version}/${fmw_product}/prompt_passwords.sh ]; then
    source $workdir/script/${weblogic_version}/${fmw_product}/prompt_passwords.sh
  fi
fi

# Copy the installer files to the remote hosts
if [ "$1" ]; then
  export rworkdir=/tmp/install_wls.$$ # remote working directory
  for machine in "${MACHINES[@]}"; do
    if [ "$machine" != "$(hostname)" ]; then
      tar czf - install.sh config script| ssh -o BatchMode=yes $machine "mkdir $rworkdir $rworkdir/log $rworkdir/temp && cd $rworkdir && tar xzf -" || exit 1
    fi
  done
fi

##################################
# Perform the installation steps #
##################################
. $CADENCE

if [ "$1" ]; then
  for machine in "${MACHINES[@]}"; do
    if [ "$machine" != "$(hostname)" ]; then
      ssh -o BatchMode=yes $machine "rm -rf $rworkdir"
    fi
  done
fi
rm -rf $workdir/temp
exit $step_rc # return code of last executed step