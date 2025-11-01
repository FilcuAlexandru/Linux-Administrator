#!/bin/bash
#
# Create README and preferences files
# Created: 2018-11-19 dkovacs of virtual7

cd "$(dirname $0)/.."; export workdir="$(pwd)"
. $workdir/script/functions.sh


if [ "$ADMIN_CHANNEL_ENABLED" == "true" ]; then
  port=${ADMINPORT[$ADMINSERVER_NAME]}
else
  port=${SSLPORT[$ADMINSERVER_NAME]}
fi 
consoleUrl1="https://${LISTENADDRESS[$ADMINSERVER_NAME]}:$port/console"
consoleUrl2="https://$(getIPForName ${LISTENADDRESS[$ADMINSERVER_NAME]}):$port/console"

# Put a README file in the home directory
cat >~/README.$DOMAIN_NAME <<EOF
================================================================================
                        WebLogic Domain $DOMAIN_NAME
================================================================================
Console: $consoleUrl1
         $consoleUrl2

Domain Home:  $ASERVER_HOME
Admin Tools:  $ASERVER_HOME/custom_scripts

Control Menu: $ASERVER_HOME/custom_scripts/menu-control.sh
Control CLI:  $ASERVER_HOME/custom_scripts/command-control.sh
Logs:         $LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME
EOF
#readme_cmd="cat ~/README.$DOMAIN_NAME"
#if [ ! -f ~/.profile ] || [ ! "$(grep -F "$readme_cmd" ~/.profile)" ]; then
#  echo "$readme_cmd" >>~/.profile
#fi

# Create a file for convenience settings
cat >~/user-prefs.$DOMAIN_NAME <<EOF
#
# The following aliases and variables are for convenience purposes only.
# No other scripts should rely on any of these settings.
alias lt='ls -lt'
alias cdcs='cd $ASERVER_HOME/custom_scripts'
DH=$ASERVER_HOME
MH=$ORACLE_HOME
WH=$MH/wlserver
LH=$LOGDIR_PATH/$WLS_OS_USER/$DOMAIN_NAME
EOF
#ll=". ~/user-prefs.$DOMAIN_NAME"
#if [ ! -f ~/.profile ] || [ ! "$(grep -F "$prefs_cmd" ~/.profile)" ]; then
#  echo "$prefs_cmd" >>~/.profile
#fi

# Remove the unnecessary nodemanager confguration from the Administration Server
# directory and add a README file with the actual node manager directories.
rm $ASERVER_HOME/nodemanager/*
cat >$ASERVER_HOME/nodemanager/README <<EOF
Node manager home can be found on the machines [${MACHINES[@]}] at
$MSERVER_HOME/nodemanager

EOF