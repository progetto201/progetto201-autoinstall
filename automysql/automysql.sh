#!/bin/bash
#
# This script installs and configures hostapd.
#
# maintenance/documentation infos:
# author="mario33881"
# version="02_01 2020-01-15"
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
logfile="automysql.log" # script log file

# -- FUNCTIONS

########################################################################
#                                                                      #
#                           MYSQL FUNCTIONS                            #
#                                                                      #
########################################################################

mysqlinstall(){
    # installs mysql

    trap 'logger "MYSQL" "Failed installing Mysql" "false" "${logfile}" "${?}"' ERR

    logger "MYSQL" "Installing Mysql..." true "${logfile}"
    
    { 
        sudo apt-get install mysql-server -y
    } || {
        # Latest versions of raspbian throws "mysql-server has no installation candidate" error
        # https://mariadb.com/newsroom/press-releases/mariadb-replaces-mysql-as-the-default-in-debian-9/
        sudo apt-get install default-mysql-server -y
    }

    logger "MYSQL" "Done installing Mysql" true "${logfile}"
}


apacherestart(){
    # restarts apache

    trap 'logger "APACHE" "Failed restarting Apache" "false" "${logfile}" "${?}"' ERR

    logger "APACHE" "Restarting Apache..." true "${logfile}"
    
    sudo service apache2 restart

    logger "APACHE" "Done restarting Apache" true "${logfile}"
}


mysqlforphp(){
    # installs mysql for php and calls apacherestart

    trap 'logger "MYSQL" "Failed installing Mysql for PHP" "false" "${logfile}" "${?}"' ERR

    logger "MYSQL" "Installing Mysql for php..." true "${logfile}"
    
    sudo apt-get install php-mysql -y

    logger "MYSQL" "Done installing Mysql for PHP" true "${logfile}"
}


mysqlrootchangepass(){
    # changes 'root' password (for php to connect to the database)

    trap 'logger "MYSQL" "Failed changing mysql root password" "false" "${logfile}" "${?}"' ERR

    pass="$1"
    mysql_grant="GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '${pass}'"

    logger "MYSQL" "Changing Mysql root password..." true "${logfile}"
    
    sudo mysql -e "${mysql_grant};FLUSH PRIVILEGES;"

    logger "MYSQL" "Done changing mysql root password" true "${logfile}"
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    update
    echo ""
    
    if [ $# -gt 0 ] ; then
        num=-1
        for ARGUMENT in "$@"
        do
            
            if [ $((num - 1)) = 0 ] ; then
                mysqlrootchangepass "$ARGUMENT"
                num=-1
            else
                if [ "$ARGUMENT" = "-mysql" ] ; then
                    mysqlinstall
                fi

                if [ "$ARGUMENT" = "-mysqlforphp" ] ; then
                    mysqlforphp
                    apacherestart
                fi
            fi

            if [ "$ARGUMENT" = "-mysqlpass" ] ; then
                num=1
            fi

        done

        exit 0

    else
        echo "At least one param expected:"
        echo "-mysql : installs mysql"
        echo "-mysqlforphp : installs mysql for php"
        echo "-mysqlpass <pass> : changes root password to <pass>"
        echo ""
        echo "> Order is important!"
    fi
    exit 1
fi