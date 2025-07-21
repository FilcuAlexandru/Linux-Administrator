#!/bin/bash

##############################################################################################
# Created by Filcu Alexandru                                                                 #
# Version 0.1                                                                                #
# Date: 14.05.2025                                                                           #
# A simple Linux script that can be modified and configured to stop services on a VM/Server  #
# Use with systemd unit files                                                                #
##############################################################################################

# Services to stop
SERVICES=("{Replace-Service-Name-1}" "{Replace-Service-Name-2}" "{Replace-Service-Name-3}" "{Replace-Service-Name-4}" "{Replace-Service-Name-5}")

# Custom messages for each service
declare -A SERVICE_DESCRIPTION=(
    ["{Replace-Service-Name-1}"]="Stopping {Replace-Service-Name-1} Services"
    ["{Replace-Service-Name-2}"]="Stopping {Replace-Service-Name-2} Services"
    ["{Replace-Service-Name-3}"]="Stopping {Replace-Service-Name-3} Services"
    ["{Replace-Service-Name-4}"]="Stopping {Replace-Service-Name-4} Services"
    ["{Replace-Service-Name-5}"]="Stopping {Replace-Service-Name-5} Services"
)

echo "Stopping services..."

for service in "${SERVICES[@]}"; do
    echo "------------------------------------"
    echo "${SERVICE_DESCRIPTION[$service]}"
    echo "Stopping service: $service.service"
    sudo systemctl stop "$service.service"

    sleep 2

    STATUS=$(systemctl is-active "$service.service")
    if [ "$STATUS" == "inactive" ]; then
        echo "$service.service stopped successfully."
    else
        echo "Failed to stop $service.service (Status: $STATUS)."
    fi
done

echo "------------------------------------"
echo "All services have been processed."
