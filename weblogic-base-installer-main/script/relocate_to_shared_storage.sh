#!/bin/bash
#
# Relocate the Administration Server domain directory to shared storage
# Created: 2017-09-21 dkovacs of virtual7
#
cd "$(dirname $0)/.."; export workdir="$(pwd)"
. $workdir/script/functions.sh

msg "Relocating the Administration Server domain directory on host $(hostname) to $SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME"
mkdir -p "$(dirname $ASERVER_HOME)" "$SHAREDSTORAGE_PATH/domains" &&
  if [ -e "$ASERVER_HOME" ]; then
    if [ ! -L "$ASERVER_HOME" ]; then
      # Cleanup and move domain directory incl. application directory
      rm -rf "$SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME" &&
        mv "$ASERVER_HOME" "$SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME" &&
        msg "Moved $ASERVER_HOME to $SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME"
    fi
  fi
  rm -rf "$ASERVER_HOME" &&
  mkdir -p "$SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME" &&
  ln -s "$SHAREDSTORAGE_PATH/domains/$DOMAIN_NAME" "$ASERVER_HOME" || exit 1

msg "Relocating the application directory on host $(hostname) to $SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME ..."
mkdir -p "$(dirname $APPLICATION_HOME)" "$SHAREDSTORAGE_PATH/applications" &&
  if [ -e "$APPLICATION_HOME" ]; then
    if [ ! -L "$APPLICATION_HOME" ]; then
      # Cleanup and move application directory
      rm -rf "$SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME" &&
        mv  "$APPLICATION_HOME" "$SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME" &&
        msg "Moved $APPLICATION_HOME to $SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME"
    fi
  fi
  rm -rf "$APPLICATION_HOME" &&
  mkdir -p "$SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME" &&
  ln -s "$SHAREDSTORAGE_PATH/applications/$DOMAIN_NAME" "$APPLICATION_HOME"
