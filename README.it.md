# Sway Touch Bar

**Alpha sperimentale · macOS · Swift / AppKit · MIT**

[English](README.md)

Sway è un fork personale e open source di [Pock](https://github.com/pock/pock): un’app nativa per la Touch Bar con applicazioni in esecuzione, controlli di sistema e layout personalizzabile. Compare nella barra dei menu, senza icona nel Dock.

![Sway in esecuzione sulla Touch Bar di un MacBook Pro](docs/images/touch-bar.png)

> **Compatibilità verificata soltanto su MacBook Pro con Apple M1 (MacBookPro17,1), con macOS 26.6.2 (compilazione con Xcode 27.2).** Altri modelli e altre versioni di macOS non sono verificati. È un progetto sperimentale, non una versione stabile o ufficiale di Pock.

## Funzioni

- **App in esecuzione:** icone piccole delle normali applicazioni aperte, sfondo grigio chiaro per quella in primo piano e nero per le altre. Il tap attiva l’app o invia la normale richiesta macOS di riapertura, anche se non ha finestre. L’apertura effettiva di una nuova finestra dipende dall’applicazione.
- **Volume:** tap per diminuire/aumentare, tasto muto e regolazione continua con swipe.
- **Luminosità display:** tap o swipe per lo schermo integrato.
- **Retroilluminazione tastiera:** tap o swipe, con scelta esplicita della modalità automatica/manuale per le limitazioni del sensore ambientale.
- **Feedback nativo:** indicatori macOS a scomparsa per audio, display e tastiera. Su macOS Tahoe vengono richiamati i nuovi banner di Control Center.
- **Batteria, data e ora:** riempimento proporzionale, percentuale e stato di carica. Il gruppo centrale resta geometricamente centrato nello spazio disponibile della Touch Bar.
- **Tailscale:** attivazione/disattivazione della connessione locale esistente. Nove pallini spenti indicano disconnessione; quattro pallini accesi formano una T quando connesso.
- **Layout personalizzabile:** mostra/nascondi, posizione sinistra/centro/destra e riordino trascinando le righe o usando i pulsanti di spostamento. Preferenze salvate localmente.
- **Menu Sway:** personalizzazione, sospensione/ripresa della barra, stato Tailscale, luminosità tastiera automatica e uscita.

Disposizione iniziale:

| Sinistra | Centro | Destra |
| --- | --- | --- |
| App in esecuzione | Data · Batteria · Ora | Display · Tastiera · Volume / Muto · Tailscale |

Le app usano lo spazio disponibile nella propria zona e scorrono orizzontalmente. I gruppi di controllo mantengono lo swipe; le configurazioni personalizzate troppo dense usano frecce di paginazione, evitando gesti di scorrimento sovrapposti ai controlli.

## Requisiti

- Un Mac con **Touch Bar fisica**. Sway non crea una barra sostitutiva sui Mac che ne sono privi.
- Xcode e relativi strumenti da riga di comando, con configurazione iniziale e accettazione della licenza completate.
- La build ha attualmente un deployment target macOS 13.0 e successivi, ma **questo non garantisce compatibilità**: è verificata solo la configurazione M1/macOS riportata sopra.
- Facoltativo: il client [Tailscale](https://tailscale.com/) installato e autenticato, per il tasto VPN.

Non servono CocoaPods, pacchetti Homebrew, un account Apple Developer a pagamento o dipendenze Swift esterne. Il progetto Xcode e il Podfile di Pock sono sorgenti storici; per Sway usa gli script qui sotto.

## Compilazione dai sorgenti

```sh
git clone https://github.com/nannipy/sway-touchbar.git
cd sway-touchbar
bash scripts/build-sway.sh
open build/Sway.app
```

Lo script compila un’app ottimizzata per l’architettura del Mac, genera l’icona e applica una firma ad hoc locale. Il risultato è `build/Sway.app`.

Il repository distribuisce **soltanto codice e istruzioni di compilazione**. Non ci sono release dell’app scaricabili, firme Developer ID o binari notarizzati. Compila sul Mac su cui intendi usarla; architetture diverse dalla configurazione ARM64 testata non sono verificate.

Se Xcode segnala licenza o configurazione incompleta, aprilo e completa i passaggi richiesti prima di ricompilare. Se `xcrun` usa la directory di sviluppo sbagliata, controlla `xcode-select -p` e seleziona la toolchain di Xcode installata.

## Installazione e aggiornamento

Chiudi Sway prima di installare. Per il solo account corrente:

```sh
bash scripts/install-sway.sh "$HOME/Applications/Sway.app"
open "$HOME/Applications/Sway.app"
```

Oppure nella cartella Applicazioni condivisa, se il tuo account può scriverci:

```sh
bash scripts/install-sway.sh
open /Applications/Sway.app
```

L’installer compila un bundle nuovo, verifica la firma e controlla che l’eventuale destinazione esistente appartenga a Sway. La sostituisce senza mescolare file obsoleti e registra l’app in Launch Services. Le preferenze di layout restano fuori dal bundle e sopravvivono all’aggiornamento.

Poi puoi aprire Sway da Finder o Spotlight. Compare **solo nella barra dei menu**. L’apertura mostra la personalizzazione; chiudendo la finestra, la Touch Bar resta attiva. Per terminare usa **Sway → Esci da Sway**. L’avvio automatico all’accesso non è implementato.

## Personalizzazione e utilizzo

L’interfaccia dell’app usa attualmente etichette italiane; il README è disponibile in italiano e inglese.

1. Apri **Sway → Personalizza Sway…** nella barra dei menu.
2. Usa **Mostra** per mostrare o nascondere un elemento.
3. Scegli **Sinistra**, **Centro** o **Destra**.
4. Trascina le righe o usa **Sposta su / Sposta giù** per riordinarle nella zona.
5. **Ripristina layout** torna alla disposizione iniziale.

Le modifiche sono immediate. Volume, display e tastiera restano gruppi per conservare lo swipe. Premi `−/+` per gli scatti; mantieni il dito sulla Touch Bar e spostalo orizzontalmente per la regolazione continua. Il segmento centrale del volume attiva/disattiva il muto.

Il sensore ambientale può limitare la retroilluminazione della tastiera. **Luminosità tastiera automatica** permette di scegliere esplicitamente la modalità; Sway non la disattiva all’avvio. Durante l’interazione manuale sospende temporaneamente l’oscuramento per inattività e poi ripristina lo stato precedente.

### Tailscale

Installa Tailscale ed effettua prima l’accesso. Sway cerca la CLI locale in:

- `/Applications/Tailscale.app/Contents/MacOS/Tailscale`
- `/opt/homebrew/bin/tailscale`
- `/usr/local/bin/tailscale`

Il tasto legge lo stato prima di scegliere `up` o `down` e poi verifica il risultato. La connessione usa `up` senza opzioni, mantenendo le preferenze esistenti. Sway non richiede auth key, non reimposta il profilo e non sceglie un exit node. Sospendere o chiudere Sway non disconnette Tailscale.

In caso di errore apri **Sway → Stato Tailscale…** per il messaggio locale sanitizzato. Verifica prima che il client ufficiale riesca a connettersi normalmente.

## Privacy e perimetro di sicurezza

L’eseguibile Sway autonomo non contiene SDK analytics, crash reporting remoto, download di widget o aggiornamenti automatici. Le preferenze restano sul Mac. La diagnostica opzionale dei tocchi è locale e disattivata durante gli avvii normali.

Tailscale rimane un’applicazione di rete separata: Sway richiama la CLI installata per leggere lo stato e rispondere ai comandi di connessione. Lo stato viene controllato periodicamente mentre Sway è attiva. Sway non aggiunge endpoint di telemetria remota.

Il repository conserva il codice e la cronologia originali di Pock, incluse integrazioni **non compilate in Sway**. Questo non significa che tutti i sorgenti storici siano stati sottoposti ad audit o corretti. Non compilare il vecchio target Pock aspettandoti il comportamento di Sway. Questa alpha non garantisce sicurezza completa, copertura completa di accessibilità o prestazioni già misurate.

## Verifica

Test di modello e servizio, senza cambiare la connessione VPN:

```sh
bash scripts/test-sway.sh
```

Dopo la compilazione, questi controlli richiedono una sessione grafica macOS:

```sh
bash scripts/test-controls-ui.sh
bash scripts/test-layout-ui.sh
bash scripts/test-integration.sh
```

Lo script di integrazione richiede attualmente un client Tailscale installato e configurato; la build normale non lo richiede.

Il probe dei controlli usa hardware simulato. I probe di layout presentano temporaneamente una barra e finestre di prova, inclusa una **fixture al 100% in carica** per controllare i margini; non cambiano batteria o layout salvato. Le verifiche di integrazione mostrano indicatori nativi ai valori correnti, provano la riapertura di un’app temporanea e leggono lo stato Tailscale. Non attivano/disattivano la VPN e non modificano deliberatamente i livelli hardware. Screenshot ed eseguibili di prova finiscono nella cartella ignorata `build/`. Riapri Sway dopo i probe per ripristinare la barra normale.

`Tests/HardwareProbe.swift` è una diagnostica separata per lo sviluppo: le sue opzioni esplicite di esercizio **modificano e ripristinano impostazioni hardware**. Non fa parte dei comandi di verifica predefiniti.

Tap/swipe fisici, banner nativi e connessione/disconnessione Tailscale sono stati verificati sul Mac M1 indicato. Restano da ampliare le prove di sospensione/risveglio, altri dispositivi, accessibilità e consumi CPU/memoria nel lungo periodo.

## Limiti e risoluzione dei problemi

- Presentazione della Touch Bar, luminosità display/tastiera e banner nativi usano **API macOS private**, isolate negli adapter. Gli aggiornamenti del sistema possono modificarle o rimuoverle. È verificata solo la configurazione locale indicata.
- La luminosità riguarda lo schermo integrato; non c’è controllo DDC dei monitor esterni.
- Dispositivi audio senza proprietà volume/muto scrivibili potrebbero non essere regolabili. Il fallback per canali non conserva un bilanciamento stereo personalizzato.
- Per un controllo non disponibile consulta l’ultima azione nel menu Sway; i limiti del sensore ambientale per la tastiera possono essere un comportamento normale del sistema.
- Le icone includono app senza finestre. Sway invia la normale richiesta di riapertura, senza forzare comandi specifici per ogni app.
- La quota ChatGPT/Codex **non è implementata né mostrata**. Nessuno spazio è riservato al contatore.
- Non ci sono installazione di widget esterni, aggiornamenti automatici, gestione avvio all’accesso o release precompilate.
- Per segnalare un problema indica modello/chip, versioni di macOS e Xcode, passaggi per riprodurlo e, se utile, screenshot della Touch Bar. Rimuovi informazioni private dai log prima di condividerli.

## Struttura del codice

| Percorso | Contenuto |
| --- | --- |
| `Sway/` | App Swift/AppKit autonoma e bridge Objective-C isolati |
| `scripts/` | Compilazione, installazione, icona e verifiche |
| `Tests/` | Test di modello, servizio, UI e probe hardware opzionali |
| `docs/images/` | Screenshot dell’app in esecuzione per il README |
| `docs/IMPLEMENTATION.md` | Diario di sviluppo cronologico; le voci successive aggiornano quelle precedenti |
| `docs/specs/` | Requisiti e piani originali, inclusi sviluppi futuri |
| `Pock/`, `Pock.xcodeproj`, `Podfile` | Sorgenti ereditati; non usati dallo script di compilazione Sway |

## Contribuire

Leggi [CONTRIBUTING.md](CONTRIBUTING.md). Segnala i problemi di Sway [in questo fork](https://github.com/nannipy/sway-touchbar/issues), indicando hardware e sistema provati. Le modifiche agli adapter privati devono gestire simboli mancanti e specificare cosa è stato effettivamente verificato.

## Origine e licenza

Sway Touch Bar deriva da [pock/pock](https://github.com/pock/pock), a partire dal commit [`127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a`](https://github.com/pock/pock/commit/127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a). Cronologia, attribuzioni e [licenza MIT](LICENSE.md) sono conservate. Il [README originale di Pock](docs/upstream/README.pock.md) resta disponibile come riferimento storico.

Mantenuto da [nannipy](https://github.com/nannipy). Sway è un esperimento personale indipendente, non approvato o sponsorizzato da Pock, Apple o Tailscale.
