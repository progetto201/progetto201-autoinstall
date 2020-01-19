# AUTOMYSQL

## Introduzione

Questo script permette di installare / configurare MySQL, puo':
* installare mysql
* installare modulo mysql per PHP
* modificare la password di root

## Guida all'uso

Il programma accetta piu' parametri:
* "-mysql" : installa mysql
* "-mysqlforphp" : installa modulo mysql for php
* "-mysqlpass \<pass>" : cambia password root a \<pass>
> Per tornare alla condizione di default procedere al punto [Resettare al metodo di default](#resettare-al-metodo-di-default)

> Nota: Il programma esegue i programmi nell'ordine in cui sono stati passati

## Descrizione ![](https://i.imgur.com/wMdaLI0.png)

Lo script prima si assicura che si sia almeno un parametro e poi li analizza uno ad uno:
> se il parametro e' "-mysqlpass" la variariabile "num" verra' impostata a 1
per rendere vero l'if durante il ciclo successivo per permettere di leggere il parametro della nuova password

Tutte le operazioni vengono tracciate su un file di log
attraverso la funzione logger()

    logger()
La funzione richiede 5 parametri:
* Nome del software/operazione da loggare
* messaggio da loggare
* bool con successo o meno del comando
* percorso del file di log
* exit status di errore del comando
> Il successo del comando potrebbe essere ricavato dall'exit status
perche' e' standard l'exit status 0 in caso di termine normale del programma,
un exit status diverso da 0 indicherebbe un errore

### Installa MySQL
Se al programma viene passato il parametro "-mysql":
1. Verra' richiamata la funzione mysqlinstall():

        mysqlinstall()
    La funzione installa mysql con il comando
    ```sudo apt-get install mysql-server -y```

### Installa modulo mysql per PHP
Se al programma viene passato il parametro "-mysqlforphp":
1. Verranno richiamate le funzioni:

        mysqlforphp()
    La funzione installa il modulo mysql per PHP con il comando:
    ```sudo apt-get install php-mysql -y```
    
        apacherestart()
    La funzione riavvia il servizio con il comando:
    ```sudo service apache2 restart```

### Cambia password root mysql
Se al programma viene passato il parametro "-mysqlrootchangepass":
1. Viene richiamata la funzione mysqlrootchangepass() passandogli come parametro
il parametro successivo a "-mysqlrootchangepass"

        mysqlrootchangepass()
    Prende come parametro la nuova password da assegnare all'utente root di mysql
    con il comando:

    ```sudo mysql -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '${pass}';FLUSH PRIVILEGES;```
    Dove: 
    * "-e" indica l'esecuzione di istruzioni SQL
    * "GRANT" aggiunge permessi, in questo caso tutti i permessi
    * ${pass} e' la nuova password passata come parametro
    * "FLUSH PRIVILEGES" serve per rendere effettive le nuove modifiche dei permessi

    > Nota 1: Parte del comando e' contenuta in una variabile, ${mysql_grant}

#### Resettare al metodo di default
Per ritornare alla condizione originale (quella in cui ci si autentica via terminale):
1. accedere con il client mysql 
    ```
    sudo mysql -u root -p
    ```
2. inserire la password e premere invio.
3. Eseguire la seguente istruzione SQL: 
    ```sql
    UPDATE mysql.user SET plugin = 'unix_socket', Password = '' WHERE User = 'root'; FLUSH PRIVILEGES;
    ```
4. Uscire dal client con il comando ```exit```

## Requisiti ![](https://i.imgur.com/H3oBumq.png)
* Sistema operativo unix like con interprete bash

## Changelog

**2020-01-15 02_01:**

Changes:
* removed redondant debug messages
* using bash "strict mode" for better maintainability of the code
* using trap command to catch errors instead of using if statements
> Better readability

**2019-03-21 01_01:**

First commit