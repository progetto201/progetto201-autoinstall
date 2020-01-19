# AUTOINSTALL

## Introduzione

Questo script richiama tutti gli altri script che automatizzano il processo 
di installazione del sistema di monitoraggio di temperatura e umidita'

> Per la prima versione visitare il repository [progetto100](https://github.com/mario33881/progetto_100)
## Guida all'uso

Modificare il valore di queste variabili a proprio piacimento:

* devmode=true : modalita' sviluppo, non installa unclutter e installa phpmyadmin
* dhcpdns=true : se "true" verra' installato e configurato dnsmasq
* mysqlpass : password di mysql (username e' root)
* touchdevice : dispositivo con input touch
* hostapd_ip : ip statico del raspberry pi 
* hostapd_ssid : ssid dell'Access Point
* hostapd_password : password per connettersi all'AP
* dhcprange_start : primo indirizzo ip nel range DHCP
* dhcprange_stop : ultimo indirizzo ip nel range DHCP
* dhcprange_submask : subnet mask della rete (usato dal DHCP)
* domain : nome dominio della rete (dns)
* dnsmasq_conf : percorso file configurazione dnsmasq
* dnsmasq_dnsfile : percorso file hosts usato da dnsmasq

Eseguire lo script da terminale:

    ./autoinstall.sh

> Se il file non e' considerato eseguibile eseguire questo comando ```find . -type f -iname "*.sh" -exec chmod +x {} \;``` che
> si occupera' di rendere eseguibili tutti gli script nelle sotto cartelle

> Se eseguendo lo script appare l'errore "/bin/bash^m bad interpreter no such file or directory" occorre modificare gli EOL (end of line),
> per fare questo installare dos2unix con il comando ```sudo apt-get install dos2unix``` e eseguire il comando ```find . -type f -iname "*.sh" -exec dos2unix {} \;```

## Descrizione

Lo script prima verifica che tutte le variabili abbiano
valori validi usando la funzione ```verify_parameters```
che a sua volta usa le funzioni:

    ipvalid
Per verificare se gli ip sono validi

    cidrvalid
Per verificare che il cidr sia valido

    count_occurrencies
Per contare quante "/" sono contenute nelle variabili del tipo "ip/cidr"


Poi vengono aggiornati i repository di apt e vengono richiami i seguenti script:

    ./autoapachephp/install.sh -apachephp
Installa e configura Apache, PHP e libapache2-mod-php

    ./automysql/install.sh -mysql -mysqlforphp
Installa MySQL e php-mysql

Se lo script e' in modalita' produzione (devmode=false) viene installato unclutter con:
    ./internalfunctions/install.sh -unclutter
altrimenti viene installato phpmyadmin con:
    ./autoppa/autoppa.sh

Poi vengono eseguiti gli script:
    ./internalfunctions/install.sh -wallpaper -database -monsys -credentials ${mysqlpass} -chromium ${touchdevice}
Installa unclutter, imposta il wallpaper, importa il file SQL in MySQL, copia i file del sistema di monitoraggio in /var/www, 
imposta nel file delle credenziali (/var/www/credentials/credentials.ini) la password 
e configura l'avvio automatico di chromium utilizzando come dispositivo con touch input "${touchdevice}"

    ./automysql/install.sh -mysqlpass ${mysqlpass}
Modifica la password dell'utente root di MySQL
> Questa operazione viene eseguita dopo aver chiamato  "./internalfunctions/install.sh",
in questo modo non e' stata richiesta la password per importare il file SQL 

Se $dhcpdns=true viene installato e configurato dnsmasq:
    ./autodnsmasq/autodnsmasq.sh "$dhcprange_start" "$dhcprange_stop" "$dhcprange_submask" "$domain" "$dnsmasq_conf" "$dnsmasq_dnsfile" "$hostapd_ip"

Poi lo script prepara il file di configurazione per lo script autohostapd con il comando:
    
    echo -e "[HOSTAPD SETTINGS]\nip = ${hostapd_ip}\nssid = ${hostapd_ssid}\npassword = ${hostapd_password}" > autohostapd/settings.ini

Infine viene richiamato lo script autohostapd

    ./autohostapd/install.sh
Installa e configura hostapd
> Il computer si riavviera' due volte

## Requisiti
* Sistema operativo Unix like con interprete bash

## Changelog

**2020-01-18 02_01:**

Fix:
* autohostapd.sh ora finisce correttamente la sua esecuzione al riavvio del raspberry
> Lo script non aveva permessi sufficienti per scrivere sul file di log e di status
* setting wallpaper threw the error "desktop manager not active"

Changes:
* viene utilizzato bash "strict mode" per una migliore manutenibilita' del codice

Features:
* ora e' possibile scegliere se installare unclutter (se la devmode e' disattiva)
o phpmyadmin (se la devmode e' attiva)
* aggiunta la possibilita' di installare e configurare dnsmasq
* repository apt viene automaticamente aggiornato all'esecuzione di ogni script

**2019-03-21 01_01:**

First commit

## Todo/Ideas
* set firewall rules to enable dhcp, dns and http(s)
* enable password on sudo for user "pi"
* e2e testing for everything but "autohostapd"
* unit tests for:
### autoapachephp

	apacheallowhtaccess
Permette di configurare htaccess

### autodnsmasq

	config_dnsmasq
Configura dnsmasq

### autohostpad

	autostartscript
sets start on boot for the script itself

	staticip
sets static ip

	hostapdconfig
creates settings file and writes hostapd_configs in it

	hostapdsetsettings
says hostapd were the config file is

	ipforwarding
enables ip forward

	restoreiptables
set automatic restore of iptables
	
	removeautostart
removes start on boot for the script itself

### autoppa

	config_ppa
configures phpmyadmin
> Needs to be adapted for unit testing

### internalfunctions

	bootunclutter
sets start on boot for unclutter

	bootchromium
sets start on boot for chromium

	changecredentials
changes mysql password inside the credentials file

### autoinstall

	ipvalid
checks if an ip is valid

	cidrvalid
checks if a cidr is valid
	
	count_occurrencies
count the number of occurrencies of a char in a string

## Autore
mario33881