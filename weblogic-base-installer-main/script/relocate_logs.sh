#!/bin/bash
#
# Relocate logs to a dedicated filesystem
# Created: 2017-09-21 dkovacs of virtual7
#
# 2018-07-05  Separated ASERVER_HOME and MSERVER_HOME (dkovacs)
# 2018-08-03  Adapted for using configuration arrays  (dkovacs)
cd "$(dirname $0)/.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Relocating logs on host $(hostname) ..."

mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME"

# Create target files and directories
for srv in "${SERVERS[@]}"; do
  mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/servers/$srv/rotated"
done
for mcn in "${MACHINES[@]}"; do
  mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/nodemanager/$mcn/rotated"
  touch "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/nodemanager/$mcn/nodemanager.log"
  touch "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/nodemanager/$mcn/nodemanager.out"
  mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/init/$mcn/rotated"
  mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/applications/$mcn/rotated"
  mkdir -p "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/cron/$mcn/rotated"
done

# The mserver directories may not have been created yet so make sure they exist.
for mserver_name in "${!MACHINE[@]}"; do
  if [ ${MACHINE[$mserver_name]} == "$(hostname)" ]; then
    mkdir -p "$MSERVER_HOME/servers/$mserver_name"
  fi
done

# Create links for server log directories
for srv in "${SERVERS[@]}"; do
  # Set domain home path
  if [ "$srv" == "$ADMINSERVER_NAME" ]; then
    srv_home="$ASERVER_HOME"
  else
    srv_home="$MSERVER_HOME"
  fi
  # Create link if doesn't already exist
  if [ -e "$srv_home/servers/$srv" ] && [ ! -L "$srv_home/servers/$srv/logs" ]; then
    rm -rf "$srv_home/servers/$srv/logs"
    ln -s  "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/servers/$srv" "$srv_home/servers/$srv/logs"
  fi
done


ln -fs "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/nodemanager/$(hostname)/nodemanager.log" "$MSERVER_HOME/nodemanager/nodemanager.log" &&
  ln -fs "$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME/nodemanager/$(hostname)/nodemanager.out" "$MSERVER_HOME/nodemanager/nodemanager.out"

