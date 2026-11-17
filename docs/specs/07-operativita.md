# Documentazione operativa da completare durante lo sviluppo

## Sviluppo locale

Prerequisiti da registrare: modello Mac, versione macOS, versione Xcode/Swift, gestore dipendenze e relative versioni. Per ogni dipendenza includere origine e lock. Il repository attuale usa CocoaPods; non presumere che una build pulita funzioni prima di provarla.

La guida finale deve contenere comandi verificati per clone, risoluzione dipendenze, apertura workspace, build, test e pacchetto Release. Non inserire comandi di pubblicazione o schema Xcode inventati. Documentare output atteso e rimedi ai problemi effettivamente incontrati.

Usare directory di build separate dal sorgente. Non richiedere credenziali di firma per i soli test logici. Distinguere firma locale di sviluppo e distribuzione pubblica.

## Installazione e prima apertura

Preparare istruzioni per una release Sway effettivamente disponibile: provenienza del pacchetto, verifica, installazione, apertura e permessi contestuali. Se il binario non è notarizzato, dichiararne lo stato; non consigliare disattivazioni globali delle protezioni macOS.

Spiegare l'eventuale conflitto con altre utility che controllano la Touch Bar. La prima apertura deve permettere di sospendere Sway e tornare alla barra di sistema.

## Guida utente

Documentare tap, swipe, muto, app aperte e scorrimento; spiegare i simboli di batteria e quota, la data dell'ultima lettura e la differenza tra quota assente e zero. Indicare dove cambiare preferenze e come disconnettere l'integrazione.

## Diagnostica e segnalazioni

Richiedere versione Sway, macOS, modello e passi di riproduzione. I log sono facoltativi, locali e da controllare prima dell'invio. Nessuna segnalazione viene inviata automaticamente. Non includere credenziali o liste di applicazioni personali in template precompilati.

Per problemi di sicurezza predisporre `SECURITY.md` con versioni supportate e un canale privato reale scelto dal manutentore. Non inventare indirizzi di contatto. Pubblicare dettagli di vulnerabilità solo dopo valutazione del rimedio e della divulgazione.

## Disinstallazione

Uscire da Sway, disattivare avvio al login e rimuovere l'app. Documentare i percorsi Sway realmente introdotti per la cancellazione facoltativa di preferenze, log e cache. Disconnettere il provider e cancellare le credenziali Sway dal Portachiavi. Non cancellare dati Pock o di altri client.

## Release

Ogni release deve riportare commit, toolchain, architetture, versioni macOS testate, funzioni disponibili, problemi noti e stato della quota. Controllare licenze e attribuzione, dipendenze e assenza di segreti. Registrare hash del pacchetto; se firmato e notarizzato, verificarne realmente gli esiti. Un checksum da solo non sostituisce l'autenticità della firma.

Il token GitHub locale è risultato non valido durante l'ispezione iniziale: verificarne nuovamente lo stato prima della pubblicazione e completare l'autenticazione senza scrivere token nei documenti.

## Manutenzione

Controllare advisory delle versioni usate e cambi macOS che interessano API private. Aggiornare le dipendenze con test e profilo comparativo. Controllare periodicamente la compatibilità del provider quota e mostrare indisponibilità in caso di rottura. Ogni nuova funzione deve avere un budget di risorse e una decisione sui dati raccolti.

## Fonti e limiti delle informazioni

- Sorgente Pock clonato: commit `127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a`, [repository upstream](https://github.com/pock/pock).
- [Documentazione storica Pock](../upstream/README.pock.md): riferita al progetto originale.
- [Gestione dell'utilizzo GPT-6 Astra in Work e Codex](https://help.openai.com/en/articles/20001516-managing-usage-with-gpt-6-astra-in-work-and-codex): consultata durante la definizione iniziale; descrive la consultazione della quota, non dimostra l'esistenza di un'API per Sway.

Le scelte sulle API native devono essere verificate nella documentazione Apple e nella toolchain effettiva durante l'implementazione. La presente specifica non certifica compatibilità hardware, assenza di vulnerabilità o supporto pubblico per la lettura della quota.
