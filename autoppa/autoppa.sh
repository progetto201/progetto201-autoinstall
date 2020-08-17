#!/bin/bash
#
# This script installs phpmyadmin.
#
# maintenance/documentation infos:
# author="mario33881"
# version="01_02 2020-08-16"
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
logfile="autoppa.log" # script log file
ppa_version="4.9.5"   # phpmyadmin version

# -- FUNCTIONS


download_ppa(){
    # downloads and extracts phpmyadmin
    trap 'logger "PHPMYADMIN" "Failed downloading and extracting phpmyadmin" "false" "${logfile}" "${?}"' ERR
    
    logger "PHPMYADMIN" "Downloading and extracting phpmyadmin..." true "${logfile}"
	
    wget "https://files.phpmyadmin.net/phpMyAdmin/${ppa_version}/phpMyAdmin-${ppa_version}-all-languages.tar.gz"
    tar -zxvf  "phpMyAdmin-${ppa_version}-all-languages.tar.gz"

    logger "PHPMYADMIN" "Done downloading and extracting phpmyadmin" true "${logfile}"
}


verify_cksum(){
    # downloads the sha256 checksum and verifies the integrity of phpmyadmin
    trap 'logger "PHPMYADMIN" "Failed verifying sha256 checksum" "false" "${logfile}" "${?}"' ERR
    
    logger "PHPMYADMIN" "Verifying sha256 checksum..." true "${logfile}"
	
    wget "https://files.phpmyadmin.net/phpMyAdmin/${ppa_version}/phpMyAdmin-${ppa_version}-all-languages.tar.gz.sha256"
	sha256sum -c "phpMyAdmin-${ppa_version}-all-languages.tar.gz.sha256"
    
    logger "PHPMYADMIN" "Done verifying sha256 checksum" true "${logfile}"
}


verify_gpg(){
    # downloads the gpg keys to verify the signatures of phpmyadmin
    trap 'logger "PHPMYADMIN" "Failed verifying signature" "false" "${logfile}" "${?}"' ERR
    
    logger "PHPMYADMIN" "Verifying signature..." true "${logfile}"

    wget "https://files.phpmyadmin.net/phpMyAdmin/${ppa_version}/phpMyAdmin-${ppa_version}-all-languages.tar.gz.asc"
    wget https://files.phpmyadmin.net/phpmyadmin.keyring
    gpg --import phpmyadmin.keyring
    gpg --keyserver hkps://pgp.mit.edu --keyserver ha.pool.sks-keyservers.net --keyserver hkp://p80.pool.sks-keyservers.net:80 --keyserver keyserver.ubuntu.com  --recv-keys 3D06A59ECE730EB71B511C17CE752F178259BD92
    gpg --tofu-policy good CE752F178259BD92
    gpg --trust-model tofu --verify "phpMyAdmin-${ppa_version}-all-languages.tar.gz.asc"

    logger "PHPMYADMIN" "Done verifying signature" true "${logfile}"
}


install_ppa(){
    # installs phpmyadmin by putting it inside the /var/www folder
    trap 'logger "PHPMYADMIN" "Failed installing phpmyadmin" "false" "${logfile}" "${?}"' ERR
    
    logger "PHPMYADMIN" "Installing phpmyadmin..." true "${logfile}"
	
    sudo mv "phpMyAdmin-${ppa_version}-all-languages" /var/www/html/phpmyadmin
    
    logger "PHPMYADMIN" "Done installing phpmyadmin" true "${logfile}"
}


setpermissions(){
    # sets the required permissions of the www-data user for phpmyadmin
    trap 'logger "PHPMYADMIN" "Failed setting www-data permissions" "false" "${logfile}" "${?}"' ERR
    
    logger "PHPMYADMIN" "Setting www-data permissions..." true "${logfile}"
	
    sudo chown www-data.www-data /var/www/html/phpmyadmin/* -R
    
    logger "PHPMYADMIN" "Done setting www-data permissions" true "${logfile}"
}


config_ppa(){
    # installs php libraries, configures phpmyadmin and creates its db and user
    trap 'logger "PHPMYADMIN" "Failed configuring phpmyadmin" "false" "${logfile}" "${?}"' ERR

    configfile_path="/var/www/html/phpmyadmin/config.inc.php"

    logger "PHPMYADMIN" "Installing PHP libraries..." true "${logfile}"
    # Install the necessary php libraries
    sudo apt install php-mbstring php-zip php-gd -y

    # Restart apache
    sudo systemctl restart apache2

    logger "PHPMYADMIN" "Configuring phpmyadmin..." true "${logfile}"

    # Copy the example config file
    sudo cp /var/www/html/phpmyadmin/config.sample.inc.php "${configfile_path}"

    # Install pwgen to create the blowfish secret and set it
    sudo apt install pwgen -y
    sudo sed -i -e "s|cfg\['blowfish_secret'\] = ''.*|cfg['blowfish_secret'] = '$( pwgen -s 32 1 )';|" "${configfile_path}"

    # Enable multiuser login
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i\]\['controluser'\] = 'pma';|\$cfg['Servers'][\$i]['controluser'] = 'pma';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i\]\['controlpass'\] = 'pmapass';|\$cfg['Servers'][\$i]['controlpass'] = 'pmapass';|" "${configfile_path}"

    # Enable phpmyadmin features
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['pmadb'\] = 'phpmyadmin';|\$cfg['Servers'][\$i]['pmadb'] = 'phpmyadmin';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['bookmarktable'\] = 'pma__bookmark';|\$cfg['Servers'][\$i]['bookmarktable'] = 'pma__bookmark';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['relation'\] = 'pma__relation';|\$cfg['Servers'][\$i]['relation'] = 'pma__relation';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['table_info'\] = 'pma__table_info';|\$cfg['Servers'][\$i]['table_info'] = 'pma__table_info';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['table_coords'\] = 'pma__table_coords';|\$cfg['Servers'][\$i]['table_coords'] = 'pma__table_coords';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['pdf_pages'\] = 'pma__pdf_pages';|\$cfg['Servers'][\$i]['pdf_pages'] = 'pma__pdf_pages';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['column_info'\] = 'pma__column_info';|\$cfg['Servers'][\$i]['column_info'] = 'pma__column_info';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['history'\] = 'pma__history';|\$cfg['Servers'][\$i]['history'] = 'pma__history';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['table_uiprefs'\] = 'pma__table_uiprefs';|\$cfg['Servers'][\$i]['table_uiprefs'] = 'pma__table_uiprefs';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['tracking'\] = 'pma__tracking';|\$cfg['Servers'][\$i]['tracking'] = 'pma__tracking';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['userconfig'\] = 'pma__userconfig';|\$cfg['Servers'][\$i]['userconfig'] = 'pma__userconfig';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['recent'\] = 'pma__recent';|\$cfg['Servers'][\$i]['recent'] = 'pma__recent';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['favorite'\] = 'pma__favorite';|\$cfg['Servers'][\$i]['favorite'] = 'pma__favorite';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['users'\] = 'pma__users';|\$cfg['Servers'][\$i]['users'] = 'pma__users';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['usergroups'\] = 'pma__usergroups';|\$cfg['Servers'][\$i]['usergroups'] = 'pma__usergroups';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['navigationhiding'\] = 'pma__navigationhiding';|\$cfg['Servers'][\$i]['navigationhiding'] = 'pma__navigationhiding';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['savedsearches'\] = 'pma__savedsearches';|\$cfg['Servers'][\$i]['savedsearches'] = 'pma__savedsearches';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['central_columns'\] = 'pma__central_columns';|\$cfg['Servers'][\$i]['central_columns'] = 'pma__central_columns';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['designer_settings'\] = 'pma__designer_settings';|\$cfg['Servers'][\$i]['designer_settings'] = 'pma__designer_settings';|" "${configfile_path}"
    sudo sed -i -e "s|// \$cfg\['Servers'\]\[\$i]\['export_templates'\] = 'pma__export_templates';|\$cfg['Servers'][\$i]['export_templates'] = 'pma__export_templates';|" "${configfile_path}"

    logger "PHPMYADMIN" "Setting temporary folder..." true "${logfile}"

    # Create phpmyadmin's temp folder
    sudo mkdir -p /var/lib/phpmyadmin/tmp
    sudo chown -R www-data:www-data /var/lib/phpmyadmin
    echo "\$cfg['TempDir'] = '/var/lib/phpmyadmin/tmp';" | sudo tee -a "${configfile_path}" > /dev/null

    logger "PHPMYADMIN" "Creating phpmyadmin's database and user..." true "${logfile}"

    # create the phpmyadmin DB and tables
    sudo mysql < /var/www/html/phpmyadmin/sql/create_tables.sql
    
    # create a phpmyadmin account
    sudo mysql -e "GRANT SELECT, INSERT, UPDATE, DELETE ON phpmyadmin.* TO 'pma'@'localhost'  IDENTIFIED BY 'pmapass';"

    logger "PHPMYADMIN" "Done configuring phpmyadmin" true "${logfile}"   
}


# -- MAIN

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] ; then

    # update apt repositories and upgrade software
    update
    echo ""

    # move to the temp folder
    cd "/tmp"

    # download phpmyadmin
    download_ppa

    # verify the integrity and signature
    verify_cksum
    verify_gpg

    # install phpmyadmin by putting it inside /var/www
    install_ppa

    # set permissions to the user:www-data
    setpermissions

    # configure phpmyadmin
    config_ppa
fi