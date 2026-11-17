# Sicurezza e privacy

## Obiettivo e limiti

Ridurre la superficie di attacco e correggere le vulnerabilità applicabili dimostrate. Non dichiarare l'app “totalmente sicura”. Ogni risultato deve indicare revisione, ambiente, controlli svolti e limiti.

## Evidenze iniziali

Lettura del codice, non audit completo:

- AppCenter Analytics/Crashes sono dipendenze del Podfile e sono inizializzate nell'app.
- Esistono chiamate Analytics in controller e preferenze.
- Updater e Downloader usano servizi `pock.app` e `stage.pock.app`.
- WidgetsInstaller estrae archivi con Zip e installa bundle.
- TouchBarHelper contiene un percorso di riavvio privilegiato; il bridge usa STPrivilegedTask.
- Il lockfile CocoaPods è escluso dal versionamento.

Queste sono aree da verificare; non costituiscono da sole CVE o vulnerabilità sfruttabili dimostrate.

## Modello di minaccia

| Superficie | Rischio | Contromisura prevista |
|---|---|---|
| Widget eseguibili | Codice di terzi nel processo | Moduli compilati e controllati nella prima versione |
| Archivi | Traversal, symlink, espansione eccessiva | Eliminare percorso se inutilizzato; altrimenti validare prima dell'estrazione |
| Aggiornamenti | Esecuzione di pacchetti alterati | Distribuzione verificata; firma per eventuale updater futuro |
| Dipendenze | Versioni vulnerabili o non riproducibili | Inventario, lock e revisioni fissate |
| Credenziali quota | Esfiltrazione e log accidentale | Portachiavi, redazione, host autorizzati |
| Privilegi | Operazioni elevate non necessarie | Eliminare elevazione dal normale funzionamento |
| Diagnostica | Raccolta di informazioni personali | Locale, opt-in, limitata e senza contenuti sensibili |

## Piano SEC-01 — Inventario e vulnerabilità

Enumerare dipendenze dirette, transitive e codice vendorizzato con versione, origine, licenza e uso. Consultare advisory primari e database affidabili al momento dell'audit. Per ogni problema annotare identificatore, intervallo vulnerabile, versione presente, raggiungibilità, impatto e rimedio. L'assenza di un alert non prova l'assenza di problemi.

Aggiornare o rimuovere ciascuna dipendenza coinvolta, verificare compatibilità e aggiungere un test di regressione quando il difetto è riproducibile. Non usare automaticamente “latest” senza fissare la versione risolta.

## Piano SEC-02 — Telemetria zero

Rimuovere SDK AppCenter, import, inizializzazione, eventi, configurazioni e riferimenti alla telemetria nell'interfaccia. Verificare anche PockKit e i widget selezionati. Cercare altri invii di eventi o crash nei sorgenti e nei binari risolti. La diagnostica locale è disciplinata da F09.

Verificare il traffico per avvio, inattività, gesture, cambio app e uscita. Le sole richieste ammesse sono quelle delle funzioni di rete attivate dall'utente, per esempio quota o controllo release. Non confondere una funzione di rete richiesta con autorizzazione a inviare telemetria.

## Piano SEC-03 — Caricamento, download e privilegi

Disattivare percorsi di installazione e caricamento esterno se si adotta il default dei moduli integrati. Non basta nascondere il menu: rimuovere o bloccare anche aperture di documenti, URL e percorsi alternativi.

Se mantenuti in futuro, gli archivi richiedono limiti di numero file e dimensioni espanse, rifiuto di path assoluti e traversal, controllo dei symlink, directory temporanee isolate e installazione atomica. Validare firma/provenienza del codice prima di caricarlo. Verificare errori e rollback senza cancellare preventivamente l'unica copia funzionante.

Rimuovere il riavvio privilegiato della Touch Bar dalla normale esperienza. Non richiedere password amministratore per volume, luminosità o rendering. Isolare e documentare le API private: verificarne simboli, disponibilità e fallback sulla versione macOS supportata.

## Piano SEC-04 — Credenziali e rilascio

Nessun segreto nel repository, nei log, nei crash allegati o nelle fixture. Scansione prima del push; i segreti eventualmente trovati richiedono revoca, non solo rimozione dal file. CI con permessi minimi e azioni fissate a revisioni verificate. Le contribuzioni non fidate non devono accedere ai segreti di firma.

## Criterio di completamento

Inventario e controlli documentati; nessuna vulnerabilità nota applicabile ad alta gravità lasciata senza risoluzione o decisione esplicita; SDK di telemetria assenti; nessun traffico inatteso nelle prove; nessuna elevazione nel flusso ordinario; test mirati dei percorsi mantenuti. Le eccezioni devono restare visibili nelle note di rilascio.
