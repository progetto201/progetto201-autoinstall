#!/bin/bash

# Bash "strict mode" - http://redsymbol.net/articles/unofficial-bash-strict-mode/
# -e          : exit with non-0 status 
# -u          : error if undefined variable
# -p pipefail : show the first error's status code
set -euo pipefail
IFS=$'\n\t' # IFS for bash word splitting

# -- SOURCES
# shellcheck source=./utils/logger.sh
source "$(dirname "$0")/utils/logger.sh"  # defines logger function
# shellcheck source=./utils/apt.sh
source "$(dirname "$0")/utils/apt.sh"     # defines update and upgrade functions

# -- VARIABLES

logfile="autoinstall.log" # script log file

# booleans that differ the scripts result
devmode=false  # development mode
dhcpdns=true  # true = install and configure dnsmasq

# mysql related
mysqlpass="mysqlpassword"  # mysql password

# chromium related
touchdevice="Virtual core XTEST pointer"  # touch device name

# hostapd related
hostapd_ip="192.168.4.1/24"  # raspberry ip/cidr
hostapd_ssid="nameofnetwork"  # SSID of the access point
hostapd_password="longerthan8charspassword"  # PWD of the access point

# dnsmasq related
dhcprange_start="192.168.4.2" # first ip of dhcp range
dhcprange_stop="192.168.4.20" # last ip of dhcp range
dhcprange_submask="255.255.255.0" # subnet mask for dhcp

domain="progetto201.com" # domain name
    
dnsmasq_conf="/etc/dnsmasq.conf" # dnsmasq's config file
dnsmasq_dnsfile="/etc/hosts-dns" # dnsmasq's hosts file

# -- FUNCTIONS


ipvalid() {
    # Checks if ip is valid
    trap 'logger "AUTOINSTALL" "Failed ip checking" "false" "${logfile}" "${?}"' ERR

    # Set up local variables
    local ip=${1:-1.2.3.4}
    local IFS=.; local -a a=($ip)
    # Start with a regex format test
    [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
    # Test values of quads
    local quad
    for quad in {0..3}; do
        [[ "${a[$quad]}" -gt 255 ]] && return 1
    done
    return 0
}


cidrvalid(){
    # Checks if cidr is valid
    trap 'logger "AUTOINSTALL" "Failed cidr checking" "false" "${logfile}" "${?}"' ERR
    local re='^[0-9]+$'

    [[ $1 -gt -1 ]] && [[ $1 -lt 33 ]] && [[ $1 =~ $re ]]
}


count_occurrencies(){
    # Counts and "returns" how many times "$char" is in "$string"
    local string="$1"
    local char="$2"

    echo "${string}" | awk -F"${char}" '{print NF-1}'
}


verify_parameters(){
    # verifies all the parameters
    trap 'logger "AUTOINSTALL" "Failed checking variables" "false" "${logfile}" "${?}"' ERR

    # makes sure that $devmode is either true or false
    [[ "$devmode" = "true" ]] || [[ "$devmode" = "false" ]]

    # makes sure that $dhcpdns is either true or false
    [[ "$dhcpdns" = "true" ]] || [[ "$dhcpdns" = "false" ]]

    # makes sure that $mysqlpass is not empty
    [ ! -z "$mysqlpass" ]

    # makes sure that the ip has one "/" and that both cidr and ip are valid
    [[ $( count_occurrencies "$hostapd_ip" "/" ) = "1" ]]

    # splits $hostapd_ip by "/" char, output in $ADDR
    local IFS='/'; read -ra ADDR <<< "$hostapd_ip"

    # checks that the ip is valid
    ipvalid "${ADDR[0]}"
    # checks that the cidr is valid
    cidrvalid "${ADDR[1]}"

    # makes sure that $hostapd_ssid is not empty
    [ ! -z "$hostapd_ssid" ]

    # makes sure that $hostapd_password is at least 8 chars long
    [ ${#hostapd_password} -gt 7 ]

    # if $dhcpdns was true, check those variables values
    if [[ "$dhcpdns" = "true" ]] ; then
        ipvalid "$dhcprange_start"
        ipvalid "$dhcprange_stop"
        ipvalid "$dhcprange_submask"
    fi
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    logger "AUTOINSTALL" "Verifing parameters..." true "${logfile}"

    verify_parameters

    logger "AUTOINSTALL" "Updating and upgrading..." true "${logfile}"

    update
    echo ""

    logger "AUTOINSTALL" "Installing PHP and Apache" true "${logfile}"

    # install apache and php
    ./autoapachephp/autoapachephp.sh -apachephp

    logger "AUTOINSTALL" "Installing mysql and its php's library" true "${logfile}"

    # install mysql and mysql for php
    ./automysql/automysql.sh -mysql -mysqlforphp

    # check environment
    if [ "$devmode" = "false" ] ; then
        # hide mouse pointer with unclutter (production environment)
        logger "AUTOINSTALL" "Installing unclutter..." true "${logfile}"

        ./internalfunctions/internalfunctions.sh -unclutter
    else
        # install phpmyadmin (development environment)
        logger "AUTOINSTALL" "Installing phpmyadmin..." true "${logfile}"
        ./autoppa/autoppa.sh
    fi

    logger "AUTOINSTALL" "Installing and configuring monitoring system..." true "${logfile}"

    # set wallpaper, import database, install monitoring system, change credentials of monsys, set autostart of chromium with touch device input
    ./internalfunctions/internalfunctions.sh -wallpaper -database -monsys -credentials "${mysqlpass}" -chromium "${touchdevice}"

    logger "AUTOINSTALL" "Changing mysql password..." true "${logfile}"

    # change mysql password (for php)
    ./automysql/automysql.sh -mysqlpass "${mysqlpass}"

    # if $dhcpdns is true, install and configure dnsmasq
    if [ "$dhcpdns" = "true" ] ; then
        logger "AUTOINSTALL" "Installing dnsmasq..." true "${logfile}"
        # splits $hostapd_ip by "/" char, output in $ADDR
        IFS='/'; read -ra ADDR <<< "$hostapd_ip"
        ./autodnsmasq/autodnsmasq.sh "$dhcprange_start" "$dhcprange_stop" "$dhcprange_submask" "$domain" "$dnsmasq_conf" "$dnsmasq_dnsfile" "${ADDR[0]}"
        IFS=$'\n\t' # reset IFS
    fi

    logger "AUTOINSTALL" "Installing hostapd..." true "${logfile}"

    # creates settings.ini file for autohostapd
    echo -e "[HOSTAPD SETTINGS]\nip = ${hostapd_ip}\nssid = ${hostapd_ssid}\npassword = ${hostapd_password}" > autohostapd/settings.ini

    # uses settings.ini to create network using hostapd (the system will be rebooted 2 times)
    ./autohostapd/autohostapd.sh
fi