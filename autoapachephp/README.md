# AUTOAPACHEPHP

## Introduzione

Questo script bash permette di installare e configurare:
* apache
* php 
* libapache2-mod-php

> E' possibile installare i 3 software contemporaneamente
o singolarmente in base al parametro passato al programma

## Guida all'uso

Eseguire il programma:

    ./install.sh <parametro>

Dove \<parametro> puo' essere:
* "-apachephp" o "-phpapache" : lo script installa apache, abilita mod_rewrite (apache), abilita htaccess (apache), 
installa php, installa libapache2-mod-php
* "-apache" : lo script installa apache, abilita mod_rewrite (apache), abilita htaccess (apache)
* "-php" : lo script installa php
* "-phpforapache" : lo script installa libapache2-mod-php

## Descrizione ![](https://i.imgur.com/wMdaLI0.png)

Lo script gestisce il parametro in ingresso (vedi ["Guida all'uso"](#guida-all'uso) per vedere i parametri accettati) e prosegue a installare e configurare i software richiesti.

> la funzione ```usage``` visualizza come utilizzare il programma quando l'utente
> non passa parametri o ne passa in quantita' errata

### Apache
Se il parametro e' ```-apache``` vengono richiamate le funzioni:

    apacheinstall
Installa apache eseguendo il comando ```sudo apt-get install apache2 -y```

    apacherewrite
Esegue il comando ```sudo a2enmod rewrite``` per abilitare il modulo rewrite di apache

    apacherestart
Esegue il comando ```sudo service apache2 restart``` per riavviare il servizio apache

    apacheallowhtaccess
usa l'utility "sed" per modificare il file di configurazione di apache
> Il percorso del file di configurazione e' da passare come parametro

comando completo: 
```bash
sudo sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
```

Dove:
* "-i" indica la modifica diretta al file
* "```/<Directory \/var\/www\/>/,/<\/Directory>/```" indica che dove c'e' "/,/" bisogna eseguire una operazione
* "```s/AllowOverride None/AllowOverride All/```" la "s" indica la sostituzione di "AllowOverride None" con "AllowOverride All"
* "```/etc/apache2/apache2.conf```" e' il percorso del file di configurazione di apache da modificare

Poi la funzione richiama la funzione ```apacherestart``` per riavviare apache.

### PHP
Se il parametro e' ```-php``` viene richiamata la funzione ```phpinstall```:

    phpinstall
Esegue il comando ```sudo apt-get install php  -y``` per installare php

### libapache2-mod-php
Se il parametro e' ```-phpforapache``` viene richiamata la funzione ```phpforapacheinstall```:

    phpforapacheinstall()
Esegue il comando ```sudo apt-get install libapache2-mod-php  -y``` per installare libapache2-mod-php

### Apache + PHP
Se il parametro e' ```-apachephp``` o ```-phpapache```
1. Prima viene installato e configurato apache
    > Per ulteriori informazioni leggere la sezione "[Apache](#apache)"
2. Viene installato PHP
    > Per ulteriori informazioni leggere la sezione "[PHP](#php)"
3. Viene installato libapache2-mod-php
    > Per ulteriori informazioni leggere la sezione "[libapache2-mod-php](#libapache2-mod-php)"

## Requisiti ![](https://i.imgur.com/H3oBumq.png)
* Sistema operativo Unix like con interprete bash

## Changelog

**2020-01-15 02_01:**

Changes:
* removed redondant debug messages
* using bash "strict mode" for better maintainability of the code
* using trap command to catch errors instead of using if statements
> Better readability

**2019-03-21 01_01:**

First commit