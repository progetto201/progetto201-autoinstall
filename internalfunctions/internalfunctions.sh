#!/bin/bash

# Bash "strict mode" - http://redsymbol.net/articles/unofficial-bash-strict-mode/
# -e          : exit with non-0 status 
# -u          : error if undefined variable
# -o pipefail : show the first error's status code
set -euo pipefail
IFS=$'\n\t' # IFS for bash word splitting

# -- SOURCES

# shellcheck source=../utils/logger.sh
source "$(dirname "$0")/../utils/logger.sh"  # defines logger function
# shellcheck source=../utils/apt.sh
source "$(dirname "$0")/../utils/apt.sh"     # defines update and upgrade functions

# -- VARIABLES
logfile="internalfunctions.log" # script log file

# script path and its directory
scriptpath=$(realpath "$0")
dirpath=$(dirname "${scriptpath}")

# -- FUNCTIONS

########################################################################
#                                                                      #
#                          INTERNAL FUNCTIONS                          #
#                                                                      #
########################################################################


download_repository(){
    # downloads https://github.com/mario33881/progetto_100/archive/master.zip repository if needed

    # trap 'logger "INTERNAL FUNCTIONS" "Download of the repository Failed" "false" "${logfile}" "${?}"' ERR

    logger "INTERNAL FUNCTIONS" "Checking if repository as been downloaded..." true "${logfile}"

    if [ -d "../../../../progetto_100-master" ] ; then
        logger "INTERNAL FUNCTIONS" "This script has been downloaded by the repository" true "${logfile}"
        return 2

    elif [ -d "progetto_100-master" ] ; then
        logger "INTERNAL FUNCTIONS" "This script has already downloaded the repository" true "${logfile}"
        return 1
    else
        logger "INTERNAL FUNCTIONS" "Repository not found, downloading it now..." true "${logfile}"
        
        { 
            curl -LO https://github.com/mario33881/progetto_100/archive/master.zip
        } || {
            sudo apt-get install curl && curl -LO https://github.com/mario33881/progetto_100/archive/master.zip
        }
        logger "INTERNAL FUNCTIONS" "Download successfull, Unzipping file..." true "${logfile}"

        { # prova a estrarre zip, se unzip da errore non e' installato
            unzip -o master.zip
        } || { # se non e' installato installalo e estrai il zip
            sudo apt-get install unzip && unzip -o master.zip
        }

        return 0
    fi
}


unclutter(){
    # installs unclutter and calls bootunclutter

    trap 'logger "INTERNAL FUNCTIONS" "Failed installing unclutter" "false" "${logfile}" "${?}"' ERR

    logger "INTERNAL FUNCTIONS" "Installing unclutter..." true "${logfile}"

    sudo apt-get install unclutter

    logger "INTERNAL FUNCTIONS" "Done installing unclutter" true "${logfile}"
}


bootunclutter(){
    # sets unclutter to run on boot

    trap 'logger "INTERNAL FUNCTIONS" "Failed Setting start on boot unclutter" "false" "${logfile}" "${?}"' ERR

    logger "INTERNAL FUNCTIONS" "Setting start on boot unclutter..." true "${logfile}"

    unclutter_line='@unclutter -idle 0'

    sudo bash -c "echo ${unclutter_line}" | sudo cat - /etc/xdg/lxsession/LXDE-pi/autostart > temp && sudo mv temp /etc/xdg/lxsession/LXDE-pi/autostart

    logger "INTERNAL FUNCTIONS" "Done Setting start on boot unclutter" true "${logfile}"
}


bootchromium(){
    # creates sh file that starts chromium with flags and sets it to run on boot

    trap 'logger "INTERNAL FUNCTIONS" "Failed Setting start on boot chromium" "false" "${logfile}" "${?}"' ERR

    touchdevice="$1"

    bash_line='#!/bin/bash'
    touchdevice_line="touchdevice=\"${touchdevice}\""
    deviceid_line='deviceid=$(xinput list --id-only "${touchdevice}")'
    chromium_line='chromium-browser --simulate-touch-screen-with-mouse --touch-devices=${deviceid} --incognito  --emulate-touch-events --enable-touch-events --disable-features=TranslateUI --touch-events=enabled --enable-pinch --noerrdialogs --start-fullscreen --disable --disable-translate --disable-infobars --disable-suggestions-service --disable-save-password-bubble --kiosk "http://localhost/"'
    
    logger "INTERNAL FUNCTIONS" "Setting start on boot chromium..." true "${logfile}"

	sudo bash -c "echo -e '${bash_line}\n${touchdevice_line}\n${deviceid_line}\n${chromium_line}' > /home/pi/autostart_chromium.sh"
    sudo bash -c "echo @bash /home/pi/autostart_chromium.sh" | sudo cat - /etc/xdg/lxsession/LXDE-pi/autostart > temp && sudo mv temp /etc/xdg/lxsession/LXDE-pi/autostart

    logger "INTERNAL FUNCTIONS" "Done Setting start on boot chromium" true "${logfile}"
}


setwallpaper(){
    # sets custom wallpaper by first downloading the repository (if needed)

    logger "INTERNAL FUNCTIONS" "Checking repository before setting wallpaper" true "${logfile}"
    
    set +e
    download_repository
    set -e

    if [ $? -eq 2 ] ; then
        IMGPATH="../../../../progetto_100-master"
    else
        IMGPATH="progetto_100-master"
    fi

    logger "INTERNAL FUNCTIONS" "Setting wallpaper..." true "${logfile}"
    fullpath=$(/usr/bin/realpath "${IMGPATH}/images/wallpaper.png")
    
    # ignore possible errors, wallpaper is not so important
    set +e
    
    export DISPLAY=:0
    export XAUTHORITY=/home/pi/.Xauthority
    export XDG_RUNTIME_DIR=/run/user/1000
    pcmanfm --set-wallpaper="${fullpath}" --wallpaper-mode=crop

    if [ $? -eq 0 ] ; then
        logger "INTERNAL FUNCTIONS" "Done Setting wallpaper" true "${logfile}"
    else
        logger "INTERNAL FUNCTIONS" "Failed Setting wallpaper" false "${logfile}" "$?"
    fi

    set -e
}


importdatabase(){
    # imports database with tables using sql file,
    # it downloads the repository if needed

    logger "INTERNAL FUNCTIONS" "Checking repository before importing database" true "${logfile}"
    
    set +e
    download_repository
    set -e

    if [ $? -eq 2 ] ; then
        IMGPATH="../../../../progetto_100-master"
    else
        IMGPATH="progetto_100-master"
    fi

    trap 'logger "INTERNAL FUNCTIONS" "Failed Importing database" "false" "${logfile}" "${?}"' ERR

    logger "INTERNAL FUNCTIONS" "Importing database..." true "${logfile}"
    fullpath=$(/usr/bin/realpath "${IMGPATH}/raspberry/db100_100.sql")

    sudo mysql < "${fullpath}"

    logger "INTERNAL FUNCTIONS" "Done Importing database" true "${logfile}"
}


changecredentials(){
    # changes credentials file (used by php to connect to the database)

    trap 'logger "INTERNAL FUNCTIONS" "Failed Modifing database credentials" "false" "${logfile}" "${?}"' ERR

    mysql_pass="$1"
    logger "INTERNAL FUNCTIONS" "Modifing database credentials..." true "${logfile}"
    
    # sets credentials for php to connect to the database
    sudo sh -c 'echo "DB_USER100=root\nDB_PASS100=${0}" > /var/www/credentials/credentials.ini' "${mysql_pass}"

    logger "INTERNAL FUNCTIONS" "Done Modifing credentials" true "${logfile}"
}


installmonsys(){
    # installs the monitoring system app
    # the repository will be downloaded (if needed)
    # and the "progetto_100-master/raspberry/var/www" content will be copied 
    # to the "/var/www/" directory

    logger "INTERNAL FUNCTIONS" "Checking if repository has been downloaded before installing monitoring system..." true "${logfile}"

    set +e
    download_repository
    set -e

    if [ $? -eq 2 ] ; then
        RPATH="../../../../progetto_100-master"
    else
        RPATH="progetto_100-master"
    fi

    trap 'logger "INTERNAL FUNCTIONS" "Failed Installing monitoring system" "false" "${logfile}" "${?}"' ERR
    
    logger "INTERNAL FUNCTIONS" "Installing monitoring system..." true "${logfile}"
    fullpath=$(/usr/bin/realpath "${RPATH}/raspberry/var/www")

    sudo cp -r "${fullpath}/." /var/www/

    logger "INTERNAL FUNCTIONS" "Done Installing monitoring system" true "${logfile}"
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    update
    echo ""

    # set working directory = script path
    cd "$dirpath"

    if [ $# -gt 0 ] ; then
        num=-1
        for ARGUMENT in "$@"
        do

            if [ $((num - 1)) = 0 ] ; then
                changecredentials "$ARGUMENT"
                num=-1
            
            elif [ $((num - 2)) = 0 ] ; then
                bootchromium "$ARGUMENT"
                num=-1
            else
                if [ "$ARGUMENT" = "-unclutter" ] ; then
                    unclutter
                    bootunclutter
                
                elif [ "$ARGUMENT" = "-wallpaper" ] ; then
                    setwallpaper
                
                elif [ "$ARGUMENT" = "-database" ] ; then
                    importdatabase

                elif [ "$ARGUMENT" = "-monsys" ] ; then
                    installmonsys
                fi
            fi

            if [ "$ARGUMENT" = "-credentials" ] ; then
                # need to read next argument, make num - 1 true
                num=1
            fi

            if [ "$ARGUMENT" = "-chromium" ] ; then
                # need to read next argument, make num - 2 true
                num=2
            fi

        done

        exit 0

    else
        echo "At least one param expected:"
        echo "-unclutter : installs unclutters, starts on boot"
        echo "-wallpaper : sets custom wallpaper"
        echo "-database : imports database using sql file"
        echo "-credentials <pass> : sets credentials of monitoring system (root and <pass>)"
        echo "-monsys"
        echo "-chromium <device> : sets autoboot of chromium with touch using <device>"
        echo ""
        echo "> Order is important!"
    fi
    exit 1
fi