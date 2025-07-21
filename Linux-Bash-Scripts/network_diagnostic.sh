#!/bin/bash

################################################################################
# Created by Filcu Alexandru                                                   #
# Version 0.1                                                                  #
# Date: 14.05.2025                                                             #
# A simple Linux script that runs a network diagnostic report for a VM/Server  #
################################################################################

echo "==============================="
echo "   NETWORK DIAGNOSTIC REPORT   "
echo "==============================="
echo

# 1. Check Hostname
echo "1. Hostname"
echo "-----------"
echo "This shows the current hostname of your machine:"
hostname
echo

# 2. Show all Network Interfaces and their status
echo "2. Network Interfaces"
echo "---------------------"
echo "Shows all network interfaces and their current state:"
ip link show
echo

# 3. Show IP addresses assigned to interfaces
echo "3. IP Addresses"
echo "---------------"
echo "Shows all IP addresses assigned to network interfaces:"
ip addr show
echo

# 4. Show Default Gateway
echo "4. Default Gateway"
echo "------------------"
echo "Shows the default route used for outbound traffic:"
ip route show default
echo

# 5. Show full Routing Table
echo "5. Routing Table"
echo "----------------"
echo "Shows all routes known to the system:"
ip route show
echo

# 6. Show DNS Configuration
echo "6. DNS Configuration"
echo "--------------------"
echo "Shows the DNS servers configured for name resolution:"
cat /etc/resolv.conf
echo

# 7. Show active connections (TCP and UDP)
echo "7. Active Network Connections"
echo "-----------------------------"
echo "Shows current active TCP and UDP connections:"
if command -v ss &>/dev/null; then
    ss -tunap
else
    echo "The 'ss' command is not available on this system."
fi
echo

# 8. Show listening ports
echo "8. Listening Ports"
echo "------------------"
echo "Shows all ports on which the machine is listening:"
if command -v netstat &>/dev/null; then
    netstat -tuln
else
    echo "The 'netstat' command is not available on this system."
fi
echo

# 9. Check Firewall Status (firewalld)
echo "9. Firewall Status"
echo "------------------"
echo "Checks if firewalld is running and its status:"
if command -v firewall-cmd &>/dev/null; then
    firewall-cmd --state
else
    echo "firewall-cmd command not found or firewall is not running."
fi
echo

# 10. Show iptables rules
echo "10. iptables Rules"
echo "------------------"
echo "Shows the current firewall rules configured with iptables:"
if command -v iptables &>/dev/null; then
    sudo iptables -L -n
else
    echo "iptables command not found."
fi
echo

# 11. Ping Default Gateway
echo "11. Ping Default Gateway"
echo "------------------------"
echo "Pings the default gateway to check local network connectivity:"
DEFAULT_GW=$(ip route | awk '/default/ {print $3}')
if [ -n "$DEFAULT_GW" ]; then
    ping -c 4 "$DEFAULT_GW"
else
    echo "No default gateway found."
fi
echo

# 12. Ping External IP (Google DNS)
echo "12. Ping External IP (8.8.8.8)"
echo "------------------------------"
echo "Pings a public IP to check internet connectivity:"
ping -c 4 8.8.8.8
echo

# 13. DNS Lookup Test
echo "13. DNS Lookup Test"
echo "------------------"
echo "Tries to resolve www.google.com to check DNS resolution:"
if command -v host &>/dev/null; then
    host www.google.com
else
    echo "'host' command not found."
fi
echo

echo "==============================="
echo "     END OF NETWORK REPORT      "
echo "==============================="
