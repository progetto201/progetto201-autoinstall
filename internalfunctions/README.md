# INTERNALFUNCTIONS

## Introduzione
Questo script contiene tutte le funzionalita' specifiche al progetto 100+100:
* scarica il repository se non presente (se questi file vengono mossi in un percorso differente)
* installa unclutter e imposta l'avvio automatico al boot per nascondere il cursore
* imposta l'avvio automatico al boot di chromium in localhost, schermo intero, simulazione touch
* imposta il wallpaper del 100+100
* importa il file sql in mysql
* cambia il file delle credenziali usate da PHP per collegarsi a mysql
* copia i file del sistema di monitoraggio (php, css, js...) nel percorso /var/www

## Sezioni documentazione
* [Guida all'uso](#guida-all'uso)
* [Descrizione](#descrizione-)
    * [Installa unclutter](#installa-unclutter)
    * [Imposta wallpaper](#imposta-wallpaper)
    * [Importa database](#importa-database)
    * [Modifica credenziali per PHP](#modifica-credenziali-per-php)
    * [Imposta chromium all'avvio](#imposta-chromium-all'avvio)
    * [Installa sistema di monitoraggio](#installa-sistema-di-monitoraggio)
* [Requisiti](#requisiti)

## Guida all'uso
Lo script accetta diversi parametri:
* "-unclutter" : installa unclutter, imposta il suo avvio al boot
* "-wallpaper" : imposta il wallpaper
* "-database" : importa il file sql
* "-credentials \<pass>" : imposta le credenziali del sistema di monitoraggio (usarname:root e password:\<pass>)"
* "-monsys" : copia il sistema di monitoraggio in /var/www
* "-chromium \<device>" : imposta avvio automatico di chromium al boot con touch attivo che usa il digitalizzatore \<device>"

> Nota: l'ordine di esecuzione segue l'ordine con cui sono stati passati i parametri 

[Torna su](#sezioni-documentazione)

## Descrizione
Lo script scorre i parametri uno ad uno e richiama le varie funzioni

Lo script quando deve assicurarsi che certi file siano presenti, come i file del sistema di monitoraggio
o il wallpaper, avviera' la funzione download_repository()

    download_repository()
La funzione verifica prima se questo script e' presente nella cartella "progetto_100-master",
se e' così verranno usati i file attuali e la funzione restituisce come valore 2,

poi verifica se la cartella "progetto_100-master" esiste gia' nella cartella corrente,
questo significa che lo script ha gia' scaricato in precedenza il repository,
verra' usato il suo contenuto e la funzione restituisce 1

> Nota: per verificare l'esistenza della cartella viene usata la flag "-d"

Se entrambe le condizioni sono false verra' scaricato il repository
con il comando "curl" e infine viene unzippato il file scaricato
usando unzip (se non e' installato verra' installato automaticamente),
poi la funzione restituisce 0

[Torna su](#sezioni-documentazione)

### Installa unclutter
Con il parametro "-unclutter" verra' installato unclutter.
Unclutter permette di nascondere il cursore, viene installato dalla funzione unclutter()

    unclutter()
Installa unclutter con il comando: ```sudo apt-get install unclutter```
e richiama la funzione bootunclutter() per impostare il suo avvio automatico al boot

    bootunclutter()
Modifica il file ```/etc/xdg/lxsession/LXDE-pi/autostart``` per impostare l'avvio automatico,
per farlo:
1. Usa il comando echo all'interno di un nuovo interprete bash ("-c"), che esegue il comando come su
perche' non e' possibile modificare il file a causa dei permessi e il pipe viene intepretato prima del prefisso sudo,
per "visualizzare" il comando di esecuzione di unclutter

2. Viene fatto un pipe ("|") dell'output di echo sul comando cat:
* "-" sta per "output passato dal pipe"
* "/etc/xdg/lxsession/LXDE-pi/autostart" indica il contenuto del file di autostart
* ">" indica che l'output del comando deve essere scritto
* "temp" indica il file su cui deve essere scritto l'output del comando cat

> il comando cat permette di vedere il contenuto dei file, e' possibile passare
piu' file come parametri per ottenere la loro "concatenazione"

> Sempre per motivi di permessi non e' possibile scrivere direttamente il file autostart

3. Dopo il successo di questo comando ("&&") "muovi" il file "temp" in "/etc/xdg/lxsession/LXDE-pi/autostart",
sostituendo il file autostart

Ora il contenuto di autostart sara' '@unclutter -idle 0' come prima riga del file
e subito dopo e' presente il vecchio contenuto del file

[Torna su](#sezioni-documentazione)

### Imposta wallpaper
Con il parametro "-wallpaper" lo script imposta come wallpaper il file png ```images/wallpaper.png```.
Lo script richiama la funzione setwallpaper()

    setwallpaper()
Richiama la funzione download_repository() per assicurarsi che il file sia esistente,
poi viene usato il comando ```pcmanfm --set-wallpaper ${fullpath}``` per impostare il wallpaper
> ${fullpath} e' il percorso completo del wallpaper

[Torna su](#sezioni-documentazione)

### Importa database
Con il parametro "-database" viene richiamata la funzione importdatabase()

    importdatabase()
Viene richiamata la funzione download_repository() per assicurarsi che il file sql sia esistente,
poi viene usato il comando ```sudo mysql < ${fullpath}``` per importare il file
> ${fullpath} e' il percorso completo del file sql

[Torna su](#sezioni-documentazione)

### Modifica credenziali per PHP
Con il parametro "-credentials" viene richiamata la funzione changecredentials()
> Nota: il parametro successivo verra' usato come password

    changecredentials()
La funzione prende come parametro la password per accedere al database mysql
e la usa per scrivere sul file ```/var/www/credentials/credentials.ini```,
il file di configurazione usato da PHP per connettersi a mysql

> Per motivi di permessi il comando viene eseguito come sudo in un interprete sh,
perche' echo non accetta la modalita' sudo

Il comando usato per scrivere il file di configurazione e':
```sudo sh -c 'echo "DB_USER100=root\nDB_PASS100=${0}" > /var/www/credentials/credentials.ini' ${mysql_pass}```
Dove:
* ```-c``` indica l'esecuzione di un comando
* ```echo "DB_USER100=root\nDB_PASS100=${0}"``` esegue l'echo ( ${0} e' un parametro passato all'interprete, ${mysql_pass} )
* ```>``` indica la scrittura dell'output su file
* ```/var/www/credentials/credentials.ini``` e' il percorso del file da scrivere

[Torna su](#sezioni-documentazione)

### Imposta chromium all'avvio
Con il parametro "-chromium" viene richiamata la funzione bootchromium()
> Nota: il parametro successivo verra' usato per indicare il nome del digitalizzatore (usato per il touch)

    bootchromium()
La funzione crea uno script che fa eseguire chromium all'avvio,
questo script viene creato attraverso un altro interprete bash
per motivi di permessi attraverso sudo
> echo non accetta prefisso sudo

Lo script creato ( percorso ```/home/pi/autostart_chromium.sh``` ) avra' come prima riga la shebang che indica di usare come interprete bash,
la seconda riga definisce la variabile "touchdevice" con il nome del dispositivo (passato come parametro),
la terza riga definisce la variabile "deviceid" come output del comando ```xinput list --id-only "${touchdevice}"```
dove:
* "list" indica di visualizzare una lista dei dispositivi xinput
* "--id-only" indica di visualizzare solo gli id dei dispositivi
* "${touchdevice}" e' il nome del dispositivo

Quindi "deviceid" ora contiene l'id del digitalizzatore

L'ultima riga serve per eseguire chromium a cui vengono passate diverse flag:
* "--simulate-touch-screen-with-mouse" permette di simulare il touch screen in chromium (di norma chromium viene usato con il mouse)
* "--touch-devices=${deviceid}" specifica l'id del dispositivo che permette di utilizzare operazioni via touch
* "--emulate-touch-events", "--enable-touch-events", "--touch-events=enabled" e "--enable-pinch" servono per abilitare le operazioni touch
* "--incognito", "--disable-features=TranslateUI", "--noerrdialogs", "--disable", "--disable-translate", "--disable-infobars", "--disable-suggestions-service" e "--disable-save-password-bubble"
  cercano di togliere tutte le notifiche relative alla "chiusura non corretta di chromium", alla "traduzione della pagina"
* "--start-fullscreen" esegue chromium a schermo intero
* "--kiosk" nasconde i menu del browser
* "http://localhost/" e' l'URL su cui aprire chromium

> Nota: alcune di queste flag potrebbero essere inutili a causa della loro "volatilita'" essendo funzionalita' sperimentali, mai definitivamente implementate
e in certi casi rimosse successivamente.

Dopo aver creato lo script di avvio di chromium deve essere impostato la sua esecuzione al boot:
viene aggiunta la riga "@bash /home/pi/autostart_chromium.sh" al file ```/etc/xdg/lxsession/LXDE-pi/autostart```,
per farlo:
1. Usa il comando echo all'interno di un nuovo interprete bash ("-c"), che esegue il comando come su
perche' non e' possibile modificare il file a causa dei permessi e il pipe viene intepretato prima del prefisso sudo,
per "visualizzare" il comando di esecuzione dello script per l'avvio di chromium

2. Viene fatto un pipe ("|") dell'output di echo sul comando cat:
* "-" sta per "output passato dal pipe"
* "/etc/xdg/lxsession/LXDE-pi/autostart" indica il contenuto del file di autostart
* ">" indica che l'output del comando deve essere scritto
* "temp" indica il file su cui deve essere scritto l'output del comando cat

> il comando cat permette di vedere il contenuto dei file, e' possibile passare
piu' file come parametri per ottenere la loro "concatenazione"

> Sempre per motivi di permessi non e' possibile scrivere direttamente il file autostart

3. Dopo il successo di questo comando ("&&") "muovi" il file "temp" in "/etc/xdg/lxsession/LXDE-pi/autostart",
sostituendo il file autostart

[Torna su](#sezioni-documentazione)

### Installa sistema di monitoraggio
Con il parametro "-monsys" viene richiamata la funzione installmonsys()

    installmonsys()
Richiama la funzione download_repository() per assicurarsi che i file del sistema di monitoraggio siano esistenti,
poi copia ( con "cp -r", in modalita' recursiva essendo una cartella) il contenuto della cartella raspberry/var/www/ in /var/www

[Torna su](#sezioni-documentazione)

## Requisiti
* Sistema operativo Unix like con interprete bash

[Torna su](#sezioni-documentazione)

## Changelog

**2020-01-15 02_01:**

Fixes:
* setting wallpaper threw the error "desktop manager not active"

Changes:
* removed redondant debug messages
* using bash "strict mode" for better maintainability of the code
* using trap command to catch errors instead of using if statements
> Better readability

**2019-03-21 01_01:**

First commit