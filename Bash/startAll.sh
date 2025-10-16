#!/bin/bash

##############################################################################################
# Created by Filcu Alexandru                                                                 #
# Version 0.1                                                                                #
# Date: 14.05.2025                                                                           #
# A simple Linux script that can be modified and configured to start services on a VM/Server #
# Use with systemd unit files                                                                #
##############################################################################################

# Alfresco services
SERVICES=("{Replace-Service-Name-1}" "{Replace-Service-Name-2}" "{Replace-Service-Name-3}" "{Replace-Service-Name-4}" "{Replace-Service-Name-5}")

# Custom messages for each service
declare -A SERVICE_DESCRIPTION=(
    ["{Replace-Service-Name-1}"]="Starting {Replace-Service-Name-1} Services"
    ["{Replace-Service-Name-2}"]="Starting {Replace-Service-Name-2} Services"
    ["{Replace-Service-Name-3}"]="Starting {Replace-Service-Name-3} Services"
    ["{Replace-Service-Name-4}"]="Starting {Replace-Service-Name-4} Services"
    ["{Replace-Service-Name-4}"]="Starting {Replace-Service-Name-5} Services"
)

echo "Starting services..."

for service in "${SERVICES[@]}"; do
    echo "------------------------------------"
    echo "${SERVICE_DESCRIPTION[$service]}"
    echo "Starting service: $service.service"
    sudo systemctl start "$service.service"

    sleep 2

    STATUS=$(systemctl is-active "$service.service")
    if [ "$STATUS" == "active" ]; then
        echo "$service.service started successfully."
    else
        echo "Failed to start $service.service (Status: $STATUS)."
    fi
done

echo "------------------------------------"
echo "All services have been processed."
