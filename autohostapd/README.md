# AUTOHOSTAPD

## Introduzione
Questo script si occupa di installare e configurare hostapd per creare l'access point sul raspberry

## Guida all'uso
Creare un file di configurazione chiamato "settings.ini" nella stessa cartella dello script e con la seguente struttura:
```
[HOSTAPD SETTINGS]
ip = xxx.xxx.xxx.xxx
ssid = net_ssid
password = net_password
```
Eseguire lo script dal terminale

Lo script si occupera' di impostare l'ip statico, configurare hostapd, fare l'ip forwarding e di salvare le iptables

> Lo script riavviera' il raspberry e si eseguira' autonomamente fino a fine operazione

## Descrizione
Lo script, dopo essersi salvato la sua attuale posizione, verifica se e' presente un file che indica lo status dell'esecuzione dello script,
se non e' presente significa che lo script deve ancora essere eseguito
quindi viene creato il file "status.autohostapd.txt" con scritto "status='starting'".

Poi viene letto il file di status, dovrebbe ancora essere "status='starting'".

### Installazione hostapd
Se il file di status contiene "status='starting'" viene richiamata la funzione:

    hostapdinstall()
Installa hostapd con il comando ```sudo apt-get install hostapd -y```

Lo script imposta lo status dello script a "status='installed hostapd'" e
richiama le funzioni:

    hostapdstop()
Ferma il servizio hostapd con il comando ```sudo systemctl stop hostapd```

    autostartscript()
Imposta l'esecuzione automatica di questo script all'avvio.
per farlo:
1. Usa il comando echo all'interno di un nuovo interprete bash ("-c"), che esegue il comando come su
perche' non e' possibile modificare il file a causa dei permessi e echo non accetta il prefisso sudo,
per "visualizzare" il comando di esecuzione dello script

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

Ora il contenuto di autostart sara' '@lxterminal --command="${scriptpath}"' come prima riga del file
e subito dopo e' presente il vecchio contenuto del file
> ${scriptpath} e' il percorso di questo script

Viene usato lxterminal per avere uno riscontro visivo dello stato dell'esecuzione del programma (un nuovo terminale verra' aperto al prossimo riavvio)

Infine viene richiamata la funzione reboot_rpi()

    reboot_rpi()
Esegue il comando ```sudo reboot``` per riavviare il sistema

### Dopo il primo riavvio

Durante il boot del sistema il file autostart e' stato interpretato, viene eseguito lo script da lxterminal

Lo script legge la prima riga del file "status.autohostapd.txt" e legge "status='installed hostapd'",
quindi richiama le seguenti funzioni:

1. Richiama staticip():

        staticip()
    Imposta l'IP del raspberry statico inserendo nel file /etc/dhcpcd.conf le seguenti righe:
    
    ```
    interface wlan0
    static ip_address=${hostapd_ip}
    nohook wpa_supplicant
    ```
    > ${hostapd_ip} e' l'ip configurato nel file "settings.ini"

2. Poi richiama la funzione dhcpcdrestart()

        dhcpcdrestart()
    Riavvia il servizio dhcp con il comando ```sudo service dhcpcd restart```

3. Lo script richiama la funzione hostapdconfig():

        hostapdconfig()
    Crea il file di configurazione dell'access point di hostapd
    con il seguente contenuto:
    ```
    interface=wlan0
    driver=nl80211
    ssid=${hostapd_ssid}
    hw_mode=g
    channel=7
    wmm_enabled=0
    macaddr_acl=0
    auth_algs=1
    ignore_broadcast_ssid=0
    wpa=2
    wpa_passphrase=${hostapd_pass}
    wpa_key_mgmt=WPA-PSK
    wpa_pairwise=TKIP
    rsn_pairwise=CCMP
    ```
    > ${hostapd_ssid} e' l'ssid della rete, ${hostapd_pass} e' la password della rete

    Per farlo viene utilizzato il comando:
    sudo echo -e ${hostapd_configs} | sudo tee /etc/hostapd/hostapd.conf > /dev/null
    Dove:
    * "echo -e" serve per visualizzare le configurazioni, la "-e" indica di interpretare "\n" come nuova riga
    * "|" indica che viene fatto un pipe, l'output viene passato come input ad un nuovo comando
    * "tee" permette di scrivere sul file /etc/hostapd/hostapd.conf, le configurazioni verrebbero visualizzate
    * "> /dev/null" prendi l'output (visualizzazione) e inoltralo al dispositivo nullo (non visualizza configurazione)

4. Poi la funzione richiama la funzione hostapdsetsettings()

        hostapdsetsettings()
    Imposta nel file di configurazione di hostapd il percorso della configurazione dell'access point,
    per farlo viene usato il comando:
    
    ```
    replacingwith='DAEMON_CONF="/etc/hostapd/hostapd.conf"'
    toreplace='#DAEMON_CONF=""'
    sudo sed -i -e "s|${toreplace}|${replacingwith}|" /etc/default/hostapd
    ```
    Dove:
    * "-i" indica la modifica diretta del file
    * "s" indica la sostituzione di ${toreplace} con ${replacingwith}
    * "/etc/default/hostapd" e' il file di configurazione di hostapd

5. Lo script richiama la funzione ipforwarding()

        ipforwarding()
    La funzione configura l'ip forwarding con il seguente comando:
    ```
    find='#net.ipv4.ip_forward=1'
    replacingwith='net.ipv4.ip_forward=1'
    sudo sed -i -e "s/${find}/${replacingwith}/" /etc/sysctl.conf
    ```
    Dove:
    * "-i" indica la modifica diretta del file
    * "s" indica la sostituzione di ${find} con ${replacingwith}
    * "/etc/sysctl.conf" e' il file di configurazione da modificare

6. Lo script richiama la funzione setmasquerade()

        setmasquerade()
    La funzione imposta masquerade con il comando:
    ```sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE```

7. Lo script richiama la funzione saveiptables()

        saveiptables()
    La funzione salva le iptables (configurazioni firewall)
    con il comando: ```sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"```

8. Lo script richiama la funzione restoreiptables()

        restoreiptables()
    Imposta ripristino delle iptables nel file ```/etc/rc.local``` con il comando:
    ```
    newline="iptables-restore < /etc/iptables.ipv4.nat"
    sudo sed -i "$ i$newline" /etc/rc.local
    ```
    Che aggiunge la riga "iptables-restore < /etc/iptables.ipv4.nat" prima dell'ultima riga del file ("exit 0")

9. Lo script richiama la funzione removeautostart()

        removeautostart()
    La funzione rimuove questo script dall'esecuzione automatica all'avvio
    con i comandi:
    
    * ```sudo grep -v "@lxterminal --command=\"${scriptpath}\"" /etc/xdg/lxsession/LXDE-pi/autostart > lxdeautostart.temp```

        Dove:
        * "grep" permette di cercare testo in un file
        * "-v" inverte il risultato della ricerca
        * "@lxterminal --command=\"${scriptpath}\"" e' la riga da ricercare, quella che esegue lo script all'avvio
        * "/etc/xdg/lxsession/LXDE-pi/autostart" e' il file che viene eseguito ad ogni avvio
        * ">" e' un pipe che porta l'output su file
        * "lxdeautostart.temp" e' il nome di un file temporaneo

    * ```sudo cp -f lxdeautostart.temp /etc/xdg/lxsession/LXDE-pi/autostart```

        Dove:
        * "cp" copia un file
        * "-f" forza l'operazione, anche se il file nella destinazione esiste
        * "lxdeautostart.temp" file temporaneo da copiare
        * "/etc/xdg/lxsession/LXDE-pi/autostart" percorso file di destinazione

    * ```sudo rm lxdeautostart.temp```

        Dove:
        * "rm" rimuove un file
        * "lxdeautostart.temp" e' il file temporaneo da rimuovere

10. Lo script richiama la funzione hostapdunmasknenable()

        hostapdunmasknenable()
    La funzione fa l'unmask di hostapd per evitare errori che bloccano
    l'avvio di hostapd e la creazione della rete

    I comandi eseguiti sono:
    ```
    sudo systemctl unmask hostapd
    sudo systemctl enable hostapd
    sudo systemctl start hostapd
    ```

11. Lo script salva come status del programma "status='done'" nel file "status.autohostapd.txt"

12. Lo script richiama la funzione reboot_rpi() per riavviare per l'ultima volta il raspberry pi

## Requisiti
* Sistema operativo Unix like con interprete bash

## Changelog

**2020-01-15 02_01:**

Fixes:
* The script didn't have enough permissions to write the log and status files

Changes:
* removed redondant debug messages
* using bash "strict mode" for better maintainability of the code
* using trap command to catch errors instead of using if statements
> Better readability

**2019-03-21 01_01:**

First commit