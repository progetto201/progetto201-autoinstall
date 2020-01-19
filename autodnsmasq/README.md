# AUTODNSMASQ

## Introduzione
Questo script si occupa di installare e configurare dnsmasq

## Guida all'uso

Eseguire lo script specificando tutti e 7 i parametri:

    ./autodnsmasq.sh <dhcprange_start> <dhcprange_stop> <dhcprange_submask> <domain> <dnsmasq_conf> <dnsmasq_dnsfile> <localhost_ip>

Dove:   
- dhcprange_start = primo ip del range DHCP
- dhcprange_stop = ultimo ip del range DHCP
- dhcprange_submask = subnet mask della rete
- domain = nome dominio (es. 'example.com')
- dnsmasq_conf = percorso al file di configurazione di dnsmasq
- dnsmasq_dnsfile = percorso al file hosts di dnsmasq
- localhost_ip = indirizzio ip della macchina attuale (es. 192.168.4.1)

## Descrizione
Lo script aggiorna i repository di apt e aggiorna i software,
poi esegue le seguenti funzioni:

    install_dnsmasq
Installa dnsmasq utilizzando apt

    stop_dnsmasq
Ferma il servizio di dnsmasq per poterlo configurare

    config_dnsmasq
Configura dnsmasq con il range DHCP, il nome del dominio ecc...
> La funzione accetta i 6 parametri descritti nella sezione "Guida all'uso".
> Se non vengono passati la funzione utilizzera' i valori di default

    start_dnsmasq
Avvia il servizio di dnsmasq

## Requisiti
* Sistema operativo Unix like con interprete bash

## Changelog

**2020-01-18 01_01:**

First commit