# Prodotto e requisiti

## Obiettivo

Sway è un fork personale e open source di Pock per MacBook Pro M1 con Touch Bar. Deve offrire controlli immediati e informazioni essenziali, con consumo contenuto, assenza di telemetria remota e una base verificabile dal punto di vista della sicurezza.

Il nome Sway è confermato. Il lavoro deve partire semplice e vicino all'originale, preservando provenienza e attribuzione. La pubblicazione del sorgente su GitHub fa parte dell'obiettivo; la distribuzione di un'app firmata richiede preparazione separata.

## Requisiti confermati

- Volume e luminosità sempre accessibili mentre Sway presenta la propria barra.
- Volume: pulsanti aumento, diminuzione e muto; swipe per variazione continua.
- Luminosità: aumento e diminuzione al tap, regolazione continua allo swipe.
- Applicazioni utente in esecuzione rappresentate esclusivamente da icone, anche senza finestre; al tap richiedere la riapertura standard macOS (requisito aggiornato il 17 novembre); nessuna lista derivata dalle app fissate nel Dock.
- Ora, data e percentuale della batteria.
- Quota residua dell'abbonamento ChatGPT/Codex, non credito API.
- Correzione dei problemi di sicurezza noti applicabili alle versioni effettivamente utilizzate.
- Nessuna telemetria remota. Eventuale diagnostica solo locale.
- Basso utilizzo di CPU, memoria e batteria, con interazione fluida.

## Interpretazione di “sempre disponibili”

I controlli hanno spazio riservato nel layout di Sway e non scompaiono quando aumentano le app aperte. Non si promette di sovrascrivere schermate di sistema, login, blocco, interfacce protette o ogni possibile comportamento di macOS. Il comportamento al cambio applicazione, dopo sleep e dopo sblocco va provato sul Mac reale.

## Priorità

P0: compilazione riproducibile, identità separata, rimozione telemetria, sicurezza dei percorsi di caricamento e aggiornamento.

P1: volume, luminosità, app aperte, data, ora, batteria, ripristino corretto della Touch Bar.

P2: quota ChatGPT/Codex, subordinata alla disponibilità di una fonte attendibile; resta un requisito aperto se la fonte non esiste.

## Esclusioni dalla prima versione

Default proposti: niente meteo, servizi cloud propri, account Sway, sincronizzazione, marketplace, aggiornamenti silenziosi o supporto a monitor esterni per la luminosità. Niente riscrittura generale in Rust, Go o C senza prove di un vantaggio misurabile.

## Esperienza iniziale

L'utente avvia Sway, vede una spiegazione breve delle autorizzazioni realmente necessarie e attiva la barra. Una funzione non autorizzata spiega come abilitarla senza impedire l'uso delle altre. Il menu macOS espone preferenze, diagnostica locale, informazioni, sospensione e uscita. L'avvio al login è opt-in.

## Stato del repository

Base clonata: Pock, commit `127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a`. Il codice applicativo è ancora quello originale. Il README Sway e la copia storica del README Pock sono già presenti. Nessun audit completo, benchmark o build Sway è stato eseguito.
