#!/bin/bash
#
# This script installs and configures dnsmasq.
# 
# maintenance/documentation infos:
# author="mario33881"
# version="01_02 2020-08-16"

# Bash "strict mode" - http://redsymbol.net/articles/unofficial-bash-strict-mode/
# -e          : exit with non-0 status 
# -u          : error if undefined variable
# -p pipefail : show the first error's status code
set -euo pipefail
IFS=$'\n\t' # IFS for bash word splitting

# -- SOURCES

# shellcheck source=../utils/logger.sh
source "$(dirname "$0")/../utils/logger.sh"  # defines logger function
# shellcheck source=../utils/apt.sh
source "$(dirname "$0")/../utils/apt.sh"     # defines update and upgrade functions

# -- VARIABLES

logfile="autodnsmasq.log"                  # script log file

# -- FUNCTIONS 


install_dnsmasq(){
    # install dnsmasq
    trap 'logger "DNSMASQ" "Failed Installing dnsmasq" "false" "${logfile}" "${?}"' ERR
    
    logger "DNSMASQ" "Installing dnsmasq..." true "${logfile}"
    
    sudo apt-get install dnsmasq -y
    
    logger "DNSMASQ" "Done installing dnsmasq" true "${logfile}"
}


stop_dnsmasq(){
    # stop dnsmasq
    trap 'logger "DNSMASQ" "Failed stopping dnsmasq service" "false" "${logfile}" "${?}"' ERR
    
    logger "DNSMASQ" "Stopping dnsmasq service..." true "${logfile}"
    sudo systemctl stop dnsmasq
    logger "DNSMASQ" "Done stopping dnsmasq service" true "${logfile}"
}


config_dnsmasq(){
    # configure dnsmasq: dns-es and config file
    trap 'logger "DNSMASQ" "Failed configuring dnsmasq" "false" "${logfile}" "${?}"' ERR
    
    
    local dhcprange_start="${1:-192.168.4.2}"
    local dhcprange_stop="${2:-192.168.4.20}"
    local dhcprange_submask="${3:-255.255.255.0}"

    local domain="${4:-progetto201.com}"
    
    local dnsmasq_conf="${5:-/etc/dnsmasq.conf}"
    local dnsmasq_dnsfile="${6:-/etc/hosts-dns}"

    local localhost_ip="${7:-192.168.4.1}"

    logger "DNSMASQ" "Configuring dnsmasq..." true "${logfile}"

    # Move the default dnsmasq configuration
    sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig

    # Configure dnsmasq
    echo '# Use the require wireless interface' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo 'interface=wlan0' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo '# Never forward plain names (without a dot or domain part)' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo 'domain-needed' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo '# Never forward addresses in the non-routed address spaces' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo 'bogus-priv' | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "# If you don't want dnsmasq to read /etc/resolv.conf or any other" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# file, getting its servers from this file instead (see below), then" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# uncomment this." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "no-resolv" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "# If you don't want dnsmasq to poll /etc/resolv.conf or other resolv" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# files for changes and re-read them then uncomment this." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "no-poll" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "# Use external DNSes if needed" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "server=8.8.8.8" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "server=8.8.4.4" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "dhcp-range=${dhcprange_start},${dhcprange_stop},${dhcprange_submask},24h" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "# If you don't want dnsmasq to read /etc/hosts, uncomment the" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# following line." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "no-hosts" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# or if you want it to read another file, as well as /etc/hosts, use" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# this." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "addn-hosts=${dnsmasq_dnsfile}" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    
    echo "# Set this (and domain: see below) if you want to have a domain" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# automatically added to simple names in a hosts-file." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "expand-hosts" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    
    echo "# Set the domain for dnsmasq. this is optional, but if it is set, it" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# does the following things." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "# 1) Allows DHCP hosts to have fully qualified domain names, as long" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "#     as the domain part matches this setting." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo '# 2) Sets the "domain" DHCP option thereby potentially setting the' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "#    domain of all systems configured by DHCP" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo '# 3) Provides the domain part for "expand-hosts"' | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "domain=${domain}" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "# Resolve only for local requests" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "local=/${domain}/" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    echo "#Whenever /etc/resolv.conf is re-read, clear the DNS cache.  This is useful when new nameservers may" | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "#have different data than that held in cache." | sudo tee -a "${dnsmasq_conf}" > /dev/null
    echo "clear-on-reload" | sudo tee -a "${dnsmasq_conf}" > /dev/null

    logger "DNSMASQ" "Configuring dns-es..." true "${logfile}"

    # configure dns file
    echo "127.0.0.1       localhost" | sudo tee -a "${dnsmasq_dnsfile}" > /dev/null
    echo "${localhost_ip}       raspberry" | sudo tee -a "${dnsmasq_dnsfile}" > /dev/null

    logger "DNSMASQ" "Done configuring dnsmasq" true "${logfile}"
}


start_dnsmasq(){
    # starts dnsmasq service
    trap 'logger "DNSMASQ" "Failed starting dnsmasq" "false" "${logfile}" "${?}"' ERR
    
    logger "DNSMASQ" "Starting dnsmasq..." true "${logfile}"
    sudo systemctl start dnsmasq
    logger "DNSMASQ" "Done starting dnsmasq" true "${logfile}"
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    update
    echo ""

    if [ $# = 7 ] ; then
        install_dnsmasq
        stop_dnsmasq

        config_dnsmasq "$1" "$2" "$3" "$4" "$5" "$6" "$7"

        start_dnsmasq
    else
        echo "You need to pass 6 parameters to this script:"
        echo "- dhcprange_start = first ip of the DHCP range"
        echo "- dhcprange_stop = last ip of the DHCP range"
        echo "- dhcprange_submask = subnet mask of the DHCP"
        echo "- domain = domain name (ex. 'example.com')"
        echo "- dnsmasq_conf = path to the dnsmasq's config file"
        echo "- dnsmasq_dnsfile = path to the dnsmasq's hosts file"
        echo "- localhost_ip = ip of the current host (ex. 192.168.4.1)"
        
    fi
fi