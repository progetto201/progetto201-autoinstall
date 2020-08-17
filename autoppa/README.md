# AUTOPPA

## Introduzione
Questo script installa e configura phpmyadmin

## Guida all'uso
Eseguire lo script con il comando

    ./autoppa.sh

## Descrizione
Lo script aggiorna i repository di apt e i software,
imposta la directory di lavoro della cartella ```/tmp```
poi esegue le seguenti funzioni:

    download_ppa
Scarica l'archivio con phpmyadmin e lo estrae

    verify_cksum
Verifica il checksum SHA256 di phpmyadmin per
assicurare la sua integrita'

    verify_gpg
Verifica la firma digitale di phpmyadmin
per garantire la provvenienza del software

    install_ppa
Installa phpmyadmin spostando la cartella estratta
da ```download_ppa``` nella cartella ```/var/www/html```

    setpermissions
Imposta i permessi dell'utente www-data, l'utente utilizzato
da apache e da phpmyadmin e che gli permette di operare sui file

    config_ppa
Configura phpmyadmin installando le librerie di PHP necessarie,
configura il blowfish_secret, il login multiutente
e crea il database di phpmyadmin con il proprio utente
> Phpmyadmin, essendo utilizzato e utile solo durante lo sviluppo
del progetto 201, e' lasciato al minimo della configurazione richiesta
per funzionare (questo significa che anche username e password sono quelle di default,
aspetto che non dovrebbe comunque compromettere particolarmente la sicurezza essendo un utente impossibilitato
di creare e modificare database)

## Requisiti
* Sistema operativo Unix like con interprete bash

## Changelog

**2020-08-16 01_02:**

* Fix "gpg: keyserver refresh failed: No keyserver available" (added keyservers)
* Fix Permission errors
* Updated PHPMyAdmin version

**2020-01-18 01_01:**

First commit