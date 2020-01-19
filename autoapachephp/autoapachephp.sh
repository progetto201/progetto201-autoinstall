#!/bin/bash
#
# This script installs and configures Apache and PHP.
#
# The user is able to choose to install apache, php or libapache2-mod-php
# or all of them
# 
# maintenance/documentation infos:
# author="mario33881"
# version="02_01 2020-01-15"
#
#
# USAGE:
#
#    ./install.sh <parameter>
#
# Where <parameter> is:
# * "-apachephp" or "-phpapache" : the script installs apache, enables mod_rewrite (apache), 
#                                  enables htaccess (apache), installs php, installs libapache2-mod-php
# * "-apache" : the script installs apache, enables mod_rewrite (apache), enables htaccess (apache)
# * "-php" : the script installs php
# * "-phpforapache" : the script installs libapache2-mod-php
#
#
# > A message is echoed and logged before and after each command
# > (if an error is thrown the exit code is included in the message)

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

logfile="autoapachephp.log"                  # script log file
apacheconf_path="/etc/apache2/apache2.conf"  # apache configuration file path

# -- FUNCTIONS 


usage(){
    # Echoes how to use the script.
    echo "-apachephp or -phpapache : installs php, apache and the php library for apache"
    echo "-php : installs php"
    echo "-apache : installs apache (enables rewrite and htaccess)"
    echo "-phpforapache : installs the php library for apache (libapache2-mod-php)"
}


########################################################################
#                                                                      #
#                          APACHE FUNCTIONS                            #
#                                                                      #
########################################################################


apacheinstall(){
    # Installs apache using the apt package manager.
    # > the '-y' flag is respond 'yes' to the 'do you want to install ___?' question
    
    trap 'logger "APACHE" "Failed installing Apache" "false" "${logfile}" "${?}"' ERR
    
    logger "APACHE" "Installing Apache..." true "${logfile}"
    
    sudo apt-get install apache2 -y
    
    logger "APACHE" "Done installing Apache" true "${logfile}"
}


apacherewrite(){
    # Enables apache's rewrite.
    #
    # mod_rewrite helps you rewrite requested URLs, redirect one URL to another 
    # and restrict access to your website exactly as you require.
    
    trap 'logger "APACHE" "Failed enabling Rewrite" "false" "${logfile}" "${?}"' ERR

    logger "APACHE" "Enabling Rewrite..." true "${logfile}"
    
    sudo a2enmod rewrite

    logger "APACHE" "Done enabling Rewrite" true "${logfile}"
}


apacherestart(){
    # Restarts the apache service.
    trap 'logger "APACHE" "Failed restarting Apache" "false" "${logfile}" "${?}"' ERR

    logger "APACHE" "Restarting Apache..." true "${logfile}"
    
    sudo service apache2 restart
     
    logger "APACHE" "Done restarting Apache" true "${logfile}"

}


apacheallowhtaccess(){
    # Allows apache's htaccess for the '/var/www' directory.
    #
    # The 'sed' utility is used to modify the apache config file (<t_apacheconf_path>)
    # > 'AllowOverride None' is replaced with 'AllowOverride All' for the '/var/www' directory
    #
    # Params:
    # * $t_apacheconf_path = $1 : path to the apache config file

    local t_apacheconf_path="${1}"

    trap 'logger "APACHE" "Failed Allowing Htaccess" "false" "${logfile}" "${?}"' ERR

    logger "APACHE" "Allowing Htaccess..." true "${logfile}"
    
    sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' "${t_apacheconf_path}"
 
    logger "APACHE" "Done Allowing Htaccess" true "${logfile}"
}


########################################################################
#                                                                      #
#                            PHP FUNCTIONS                             #
#                                                                      #
########################################################################


phpinstall(){
    # Installs php using the apt package manager.
    # > the '-y' flag is respond 'yes' to the 'do you want to install ___?' question
    trap 'logger "PHP" "Failed Installing PHP" "false" "${logfile}" "${?}"' ERR
    
    logger "PHP" "Installing PHP..." true "${logfile}"
    
    sudo apt-get install php  -y

    logger "PHP" "Done Installing PHP" true "${logfile}"
}


phpforapacheinstall(){
    # Installs the php library for apache using the apt package manager.
    # > the '-y' flag is respond 'yes' to the 'do you want to install ___?' question
    #
    # The library enables apache to talk to PHP to interpret them.
    trap 'logger "PHP FOR APACHE" "Failed Installing PHP library for Apache" "false" "${logfile}" "${?}"' ERR
    
    logger "PHP FOR APACHE" "Installing PHP library for Apache..." true "${logfile}"
    
    sudo apt-get install libapache2-mod-php  -y
 
    logger "PHP FOR APACHE" "Done Installing PHP library for Apache" true "${logfile}"
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then
    # if the bash script isn't sourced check if the user passed one parameter
    if [ $# = 1 ] ; then
        # update apt repositories and upgrade the packages
        update
        echo ""

        if [ "$1" = "-apachephp" ] || [ "$1" = "-phpapache" ] ; then
            # the user wants to install PHP and Apache:
            # install apache, enable mod_rewrite and restart the apache service
            apacheinstall
            apacherewrite
            apacherestart

            # allow htaccess for the /var/www directory and restart the apache service
            apacheallowhtaccess "${apacheconf_path}"
            apacherestart

            # install PHP and the apache library that interprets PHP
            phpinstall
            phpforapacheinstall

        elif [ "$1" = "-apache" ]; then
            # The user wants to install Apache:
            # install apache, enable mod_rewrite and restart the apache service
            apacheinstall
            apacherewrite
            apacherestart

            # allow htaccess for the /var/www directory and restart the apache service
            apacheallowhtaccess "${apacheconf_path}"
            apacherestart

        elif [ "$1" = "-php" ] ; then
            # the user wants to install PHP
            phpinstall

        elif [ "$1" = "-phpforapache" ] ; then
            # the user wants to install the apache library that interprets PHP
            phpforapacheinstall

        else
            # the user passed a non-expected parameter, show usage
            echo "Invalid parameter, use one of these:"
            usage
            exit 1
        fi
    else
        # the user passed none or too many parameters, show usage
        echo "Execute passing one of these parameters:"
        usage
        exit 1
    fi

fi