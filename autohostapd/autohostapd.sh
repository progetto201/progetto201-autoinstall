#!/bin/bash
#
# This script installs and configures hostapd.
#
# maintenance/documentation infos:
# author="mario33881"
# version="02_01 2020-01-15"
#
#
# USAGE:
# Create a configuration file called "settings.ini" inside the script's folder with the following settings:
# ```
# [HOSTAPD SETTINGS]
# ip = xxx.xxx.xxx.xxx
# ssid = net_ssid
# password = net_password
# ```
# 
# And then execute the script from the terminal: ```./autohostapd.sh```
#

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

# script path and its directory
scriptpath=$(realpath "$0")
dirpath=$(dirname "${scriptpath}")

logfile="${dirpath}/autohostapd.log" # script log file
statusfile="${dirpath}/status.autohostapd.txt" # status file

# -- FUNCTIONS

########################################################################
#                                                                      #
#                         HOSTAPD FUNCTIONS                            #
#                                                                      #
########################################################################


hostapdinstall(){
    # installs hostapd, calls hostapdstop

    trap 'logger "HOSTAPD" "Failed Installing Hostapd" "false" "${logfile}" "${?}"' ERR

    logger "HOSTAPD" "Installing Hostapd..." true "${logfile}"
    
    sudo apt-get install hostapd -y

    logger "HOSTAPD" "Done Installing Hostapd" true "${logfile}"
}


hostapdstop(){
    # stops hostapd service, calls autostartscript

    trap 'logger "HOSTAPD" "Failed Stopping Hostapd" "false" "${logfile}" "${?}"' ERR

    logger "HOSTAPD" "Stopping Hostapd..." true "${logfile}"
    
    sudo systemctl stop hostapd
     
    logger "HOSTAPD" "Done Stopping Hostapd" true "${logfile}"
}


########################################################################
#                                                                      #
#                          SYSTEM FUNCTIONS                            #
#                                                                      #
########################################################################


autostartscript(){
    # makes this file run on the next boot, calls reboot

    local autostart_path="${1}"
    trap 'logger "AUTOHOSTAPD" "Failed Setting start on reboot" "false" "${logfile}" "${?}"' ERR

    logger "AUTOHOSTAPD" "Setting start on reboot of this script..." true "${logfile}"

    sudo bash -c "echo '@lxterminal --command=\"${scriptpath}\"'" | sudo cat - "${autostart_path}" > temp && sudo mv temp "${autostart_path}"

    logger "AUTOHOSTAPD" "Done Setting start on reboot" true "${logfile}"
}


reboot_rpi(){
    # reboots system

    trap 'sudo logger "AUTOHOSTAPD" "Failed Rebooting" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Rebooting system..." true "${logfile}"

    sudo reboot

    sudo logger "AUTOHOSTAPD" "Done Rebooting" true "${logfile}"
        
}


staticip(){
    # sets static ip, calls dhcpcdrestart
    local dhcpcd_path="${1}"

    trap 'sudo logger "AUTOHOSTAPD" "Failed Setting static ip" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Setting static ip..." true "${logfile}"

    echo -e "\ninterface wlan0\nstatic ip_address=${hostapd_ip}\nnohook wpa_supplicant" >> "${dhcpcd_path}"

    sudo logger "AUTOHOSTAPD" "Done Setting static ip" true "${logfile}"
}


dhcpcdrestart(){
    # restarts dhcpcd service
    trap 'sudo logger "AUTOHOSTAPD" "Failed Restarting DHCP service" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Restarting DHCP service..." true "${logfile}"

    sudo service dhcpcd restart
    # sudo systemctl daemon-reload

    sudo logger "AUTOHOSTAPD" "Done Restarting DHCP service" true "${logfile}"
}


hostapdconfig(){
    # creates settings file and writes hostapd_configs in it
    local hostapdconf_path="${1}"

    trap 'sudo logger "HOSTAPD" "Failed Creating Hostapd Settings File" "false" "${logfile}" "${?}"' ERR

    sudo logger "HOSTAPD" "Creating Hostapd Settings File..." true "${logfile}"

    hostapd_configs="interface=wlan0\ndriver=nl80211\nssid=${hostapd_ssid}\nhw_mode=g\nchannel=7\nwmm_enabled=0\nmacaddr_acl=0\nauth_algs=1\nignore_broadcast_ssid=0\nwpa=2\nwpa_passphrase=${hostapd_pass}\nwpa_key_mgmt=WPA-PSK\nwpa_pairwise=TKIP\nrsn_pairwise=CCMP"
	
	# sudo echo ?
    echo -e "${hostapd_configs}" | sudo tee "${hostapdconf_path}" > /dev/null

    sudo logger "HOSTAPD" "Done Creating Hostapd Settings File" true "${logfile}"
}


hostapdsetsettings(){
    # says hostapd were the config file is
    local hostapdconf_path="${1}"

    trap 'sudo logger "HOSTAPD" "Failed Setting were Hostapd Settings File is" "false" "${logfile}" "${?}"' ERR

    sudo logger "HOSTAPD" "Setting were Hostapd Settings File is..." true "${logfile}"

    toreplace='#DAEMON_CONF=""'
    replacingwith='DAEMON_CONF="/etc/hostapd/hostapd.conf"'

    sudo sed -i -e "s|${toreplace}|${replacingwith}|" "${hostapdconf_path}"

    sudo logger "HOSTAPD" "Done Setting were Hostapd Settings File is" true "${logfile}"

}


ipforwarding(){
    # enables ip forward
    local sysctl_path="$1"

    trap 'sudo logger "AUTOHOSTAPD" "Failed Setting IP forward" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Setting IP forward..." true "${logfile}"

    find='#net.ipv4.ip_forward=1'
    replacingwith='net.ipv4.ip_forward=1'

    sudo sed -i -e "s/${find}/${replacingwith}/" "${sysctl_path}"

    sudo logger "AUTOHOSTAPD" "Done Setting IP forward" true "${logfile}"
}


setmasquerade(){
    # sets routing and masquerade

    trap 'sudo logger "AUTOHOSTAPD" "Failed Setting Masquerade" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Setting Masquerade..." true "${logfile}"

    sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

    sudo logger "AUTOHOSTAPD" "Done Setting Masquerade" true "${logfile}"
}


saveiptables(){
    # saves iptables to the /etc/iptables.ipv4.nat file

    trap 'sudo logger "AUTOHOSTAPD" "Failed Saving IP Tables" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Saving IP Tables..." true "${logfile}"

    sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

    sudo logger "AUTOHOSTAPD" "Done Saving IP Tables" true "${logfile}"
}


restoreiptables(){
    # set automatic restore on boot of the iptables file

    local rclocal_path="${1}"

    trap 'sudo logger "AUTOHOSTAPD" "Failed Setting automatic IP Tables restore" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Setting automatic IP Tables restore..." true "${logfile}"

    newline="iptables-restore < /etc/iptables.ipv4.nat"

    sudo sed -i "$ i$newline" "${rclocal_path}"

    sudo logger "AUTOHOSTAPD" "Done Setting automatic IP Tables restore" true "${logfile}"
}


removeautostart(){
    # removes this script from the autostart file

    local autostart_path="${1}"

    trap 'sudo logger "AUTOHOSTAPD" "Failed Removing this script from autostart" "false" "${logfile}" "${?}"' ERR

    sudo logger "AUTOHOSTAPD" "Removing this script from autostart..." true "${logfile}"
    
    sudo grep -v "@lxterminal --command=\"${scriptpath}\"" "${autostart_path}" > lxdeautostart.temp
    sudo cp -f lxdeautostart.temp "${autostart_path}"
    sudo rm lxdeautostart.temp

    sudo logger "AUTOHOSTAPD" "Done Removing this script from autostart" true "${logfile}"
}


hostapdunmasknenable(){
    # unmasks and enables hostapd

    trap 'sudo logger "HOSTAPD" "Failed Unmasking, Enabling and Starting Hostapd" "false" "${logfile}" "${?}"' ERR

    sudo logger "HOSTAPD" "Unmasking, Enabling and Starting Hostapd..." true "${logfile}"

    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl start hostapd

    sudo logger "HOSTAPD" "Done Unmasking, Enabling and Starting Hostapd" true "${logfile}"
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    update
    echo ""

    # set working directory = script path
    cd "$dirpath"

    # get from settings.ini file raspberry ip, network password and ssid
    source <(grep = settings.ini | sed 's/ *= */=/g')
    hostapd_ip="$ip"
    hostapd_pass="$password"
    hostapd_ssid="$ssid"

    # if status file doesn't exist, create it and put starting status
    if [ ! -f "${statusfile}" ]; then
        echo "status='starting'" > "${statusfile}"
    fi

    # read status
    line=$(head -n 1 "${statusfile}")
    if [[ $line == *"status='starting'"* ]] ; then
        hostapdinstall # installs and stops hostapd
        echo "status='installed hostapd'" > "${statusfile}"

        hostapdstop
        autostartscript "/etc/xdg/lxsession/LXDE-pi/autostart"
        reboot_rpi

    elif [[ $line == *"status='installed hostapd'"* ]] ; then
        staticip "/etc/dhcpcd.conf"      # set static IP, restart DHCP
        dhcpcdrestart

        hostapdconfig "/etc/hostapd/hostapd.conf" # creates configs file and tells hostapd to use it
        hostapdsetsettings "/etc/default/hostapd"

        ipforwarding "/etc/sysctl.conf"
        setmasquerade
        saveiptables
        restoreiptables "/etc/rc.local"
        removeautostart "/etc/xdg/lxsession/LXDE-pi/autostart"
        hostapdunmasknenable

        echo "status='done'" | sudo tee "${statusfile}" > /dev/null

        reboot_rpi

    elif [[ $line == *"status='done'"* ]] ; then
        echo "Done"
    else
        echo "Unknown status"
    fi
fi