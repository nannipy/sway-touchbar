# Specifiche funzionali

## F01 — Identità, avvio e ciclo di vita

**Confermato:** nome Sway. **Default proposto:** processo nativo unico con icona nella barra dei menu.

### Implementazione

1. Separare nome visualizzato, bundle identifier, preferenze e directory Application Support da Pock. Non migrare o sovrascrivere automaticamente dati Pock.
2. Aggiornare bundle, menu, localizzazioni e metadati della release; mantenere attribuzioni e licenza. I nomi interni dei file possono restare temporaneamente originali.
3. Rilevare la disponibilità della Touch Bar. In sua assenza mostrare lo stato nel menu senza tentativi continui di ripresentazione.
4. Rendere start, stop e resume idempotenti. Registrare observer una sola volta e rimuoverli alla chiusura.
5. All'uscita ripristinare soltanto le impostazioni effettivamente modificate da Sway. Non sovrascrivere cambiamenti successivi effettuati dall'utente.
6. Dopo crash o terminazione forzata, usare uno stato di recupero minimo: non presumere che il callback di uscita sia stato eseguito.

### Accettazione

Sway e Pock non condividono preferenze o widget. Avvio ripetuto, sospensione, sleep e uscita non moltiplicano processi, timer o observer. La chiusura normale restituisce il controllo della barra al sistema.

## F02 — Layout e gestione dello spazio

**Default proposto:** app aperte nella zona flessibile; informazioni compatte; luminosità e volume nella zona fissa destra. L'ordine finale si verifica sul display reale.

### Implementazione

- Assegnare priorità massima ai controlli; mantenere dimensioni cliccabili coerenti con la Touch Bar.
- Misurare lo spazio disponibile a runtime. Evitare larghezze totali calcolate sulla sola schermata di sviluppo.
- Fare scorrere soltanto la lista app; non spostare i controlli durante lo scorrimento.
- Riservare una larghezza stabile ai valori che cambiano; usare cifre a larghezza uniforme dove possibile.
- Prevedere data compatta e quota abbreviata; testi completi nelle preferenze. Non troncare un numero rendendolo ambiguo.
- Separare i riconoscitori di gesture della lista e dei controlli per impedire conflitti.

### Accettazione

Con 0, 1, 10 e 30 app aperte, volume e luminosità restano raggiungibili. Nessuna sovrapposizione tra aree di tocco. Stati di errore e percentuali a tre cifre non rompono il layout.

## F03 — Volume e muto

**Confermato:** tap su −/+ e muto; swipe continuo nella stessa zona.

### Comportamento

- Il tap modifica il volume di un passo discreto. Default proposto: 1/16 dell'intervallo, limitato tra 0 e 100%.
- Il tap sul muto alterna lo stato muto senza perdere il livello precedente, se il dispositivo lo permette.
- Lo swipe modifica il livello rispetto al punto iniziale del gesto, evitando salti al primo contatto.
- Il gesto termina al rilascio o alla cancellazione; uno swipe non deve generare anche un tap.
- La barra riflette cambiamenti esterni e il dispositivo audio attualmente selezionato.
- Un'uscita che non espone il volume software mostra un controllo indisponibile con spiegazione nel menu; non simulare valori.

### Implementazione

1. Creare un servizio audio con snapshot iniziale e notifiche di cambio volume, muto e dispositivo.
2. Usare CoreAudio quando applicabile e verificare le proprietà effettivamente scrivibili.
3. Implementare una macchina di stato della gesture: inattivo, contatto, trascinamento, conclusione/cancellazione.
4. Adottare una soglia di movimento iniziale proposta di 4 punti, da tarare sull'hardware.
5. Accorpare gli aggiornamenti durante lo swipe e inviare sempre il valore finale; evitare processi shell o AppleScript per ogni movimento.
6. Scollegare listener del dispositivo precedente e risincronizzare sul cambio uscita.

### Accettazione

Provare altoparlanti integrati, cuffie e un'uscita non regolabile se disponibile. Verificare estremi, muto, variazioni da tastiera, cambio dispositivo durante lo swipe e cancellazione del gesto. Un gesto produce una sola modalità di azione.

## F04 — Luminosità

**Confermato:** tap −/+ e swipe continuo. **Default proposto:** display integrato soltanto.

### Implementazione

1. Incapsulare accesso alla luminosità in un servizio separato: leggere, impostare, segnalare indisponibilità.
2. Verificare il meccanismo compatibile con M1 e macOS di destinazione. Documentare ogni API privata necessaria e isolarla in un adapter.
3. Riutilizzare la logica delle gesture F03, con intervallo normalizzato 0–1 e passo proposto 1/16.
4. Non modificare la preferenza di luminosità automatica. Sincronizzare le variazioni del sistema, con notifiche dove disponibili e polling limitato solo se indispensabile.
5. Rileggere lo stato dopo wake e cambi di configurazione display; evitare tentativi ripetuti quando il display non è disponibile.

### Accettazione

Tap, swipe, minimo e massimo sono coerenti con il display. Testare regolazione automatica attiva, cambio da tastiera, sleep/wake e uso con monitor esterno. Nessun comando deve indirizzare per errore il monitor esterno.

## F05 — Applicazioni in esecuzione e riapertura

**Confermato, aggiornamento del 17 novembre:** mostrare tutte le app utente in esecuzione, anche senza finestre. Questo sostituisce il filtro sulle sole app con finestre richiesto in precedenza. Icone soltanto, nessuna lista di app fissate ma chiuse.

- NSWorkspace fornisce processi regolari e notifiche di avvio, terminazione e attivazione. Escludere Sway e processi di servizio.
- Al tap usare la riapertura standard Launch Services, attivando l'app e riutilizzando l'istanza corrente. L'app decide se creare una finestra, riaprire un documento o mostrare la propria schermata iniziale; non inviare scorciatoie globali o leggere documenti personali.
- Gestire errori e tap ripetuti mentre la riapertura è pendente. Se l'app termina prima del tap, il bundle conosciuto può essere riaperto normalmente.
- Ordine stabile, un'icona per app e indicazione grigia dell'app attiva. Immagini18pt, aree di tocco36×28pt; nessuno sfondo blu.
- Nessun polling delle finestre è necessario con questo requisito. Nomi accessibili anche senza testo visibile.

Accettazione: app con e senza finestre, app nascoste/minimizzate, più finestre, terminazione prima del tap, riapertura fallita e tap rapidi. Verificare con una fixture che il reopen raggiunga un'app senza finestre; non generalizzare l'apertura di una nuova finestra a software che ignora l'evento.

## F06 — Ora e data

**Default proposto:** ora senza secondi, formato locale, data compatta nella barra.

### Implementazione

Usare calendario, lingua e fuso del sistema; formatter riutilizzati. Pianificare l'aggiornamento al minuto successivo con tolleranza appropriata. Aggiornare anche su cambio data, ora di sistema, fuso, locale e wake. Evitare un timer al secondo per un'interfaccia che mostra minuti. Mostrare la data completa nelle preferenze o nel menu.

### Accettazione

Verificare mezzanotte, cambio fuso, formato 12/24 ore, cambio lingua e ripresa dopo sospensione. La larghezza resta stabile e il primo rendering è immediato.

## F07 — Batteria

### Implementazione

Leggere la batteria interna attraverso i servizi di alimentazione macOS e registrare notifiche di variazione. Calcolare la percentuale soltanto con capacità valida; distinguere alimentazione a rete, carica, batteria e dato sconosciuto. Non mostrare 0% quando la lettura fallisce. Non stimare autonomia residua nella prima versione. Aggiornare il rendering solo quando cambia il valore mostrato.

### Accettazione

Provare collegamento e scollegamento alimentatore, carica completa e wake. Simulare dati assenti, capacità zero e percentuali fuori intervallo nei test del modello. Nessun crash o percentuale inventata.

## F08 — Quota dell'abbonamento ChatGPT/Codex

**Confermato:** quota residua dell'abbonamento. **Da validare:** disponibilità di una fonte supportata e leggibile da Sway.

### Contratto del dato

Ogni quota contiene: identificatore della finestra o del modello, unità, residuo se fornito, totale se fornito, percentuale se ricavabile legittimamente, istante di reset se noto, istante del campionamento e provenienza. Un dato sconosciuto resta opzionale. Non convertire percentuali in token senza un totale attendibile; non sommare finestre o quote diverse.

### Stati visibili

Disattivato, autenticazione necessaria, caricamento, aggiornato, dato scaduto, servizio indisponibile e integrazione non supportata. Una quota a zero è distinta da un errore. Se sono presenti più finestre, etichettarle nelle preferenze; la barra mostra la finestra selezionata.

### Piano di implementazione

1. Verificare documentazione ufficiale e capacità disponibili al momento dell'implementazione; registrare fonte e data della verifica.
2. Valutare una API ufficiale o un'interfaccia locale documentata. Nessuna promessa di endpoint pubblico è contenuta in questa specifica.
3. Non leggere cookie del browser o credenziali di altre app. Eventuali metodi non documentati richiedono valutazione separata e una decisione esplicita sul loro uso.
4. Implementare un provider astratto e un provider fittizio esclusivamente per test, marcato come simulazione.
5. Se autorizzata e supportata, conservare la credenziale nel Portachiavi e inviarla solo al servizio previsto. Prevedere disconnessione e cancellazione.
6. Default proposto: refresh ogni 5 minuti solo con integrazione attiva, refresh manuale con limite di frequenza, backoff su errori e rispetto delle indicazioni del server.
7. Default proposto: dopo 15 minuti senza successo marcare il dato come vecchio, mantenendo visibile l'ora dell'ultima lettura. Non azzerarlo.
8. Se nessuna fonte è utilizzabile, mostrare “Non disponibile” e documentare il blocco; non dichiarare F08 completata.

### Accettazione

Testare quota multipla, zero reale, reset, rete assente, credenziali revocate, risposta incompleta, rate limit e dato scaduto. Verificare con l'account reale soltanto dopo aver definito l'integrazione. La funzione non deve bloccare controlli o avvio.

## F09 — Preferenze, autorizzazioni e diagnostica

### Implementazione

Preferenze native: avvio al login, visibilità dei moduli informativi, ordine consentito, formato data/ora, integrazione quota e diagnostica. Volume e luminosità restano nella zona fissa del layout iniziale. Versionare lo schema delle preferenze e applicare default alle chiavi mancanti.

Richiedere solo permessi necessari a funzioni implementate, nel momento in cui servono. Per un diniego mostrare istruzioni contestuali. Non chiedere accesso completo al disco per comodità.

Diagnostica locale disattivata per default nelle release; se attivata, registrare errori e tempi aggregati senza nomi delle app, contenuti, cookie, credenziali o identificativi account. Proposta: rotazione con massimo complessivo di 5 MB e conservazione di 7 giorni. L'esportazione è manuale e preceduta da una visualizzazione del contenuto.

### Accettazione

Le preferenze persistono, input corrotti tornano a un default valido, credenziali e segreti non compaiono nei file. Il log resta entro i limiti e nessun export viene inviato automaticamente.

## F10 — Widget e aggiornamenti

### Default proposto per il primo rilascio

Integrare e compilare i moduli necessari insieme a Sway. Disattivare download automatici, catalogo remoto e caricamento indiscriminato dei widget Pock. Questa scelta riduce il perimetro ma va registrata come modifica di compatibilità.

### Implementazione

Mappare prima le dipendenze tra app, PockKit e repository dei widget: i widget richiesti non sono tutti implementati nel repository principale. Recuperare sorgenti e licenze dei componenti selezionati, fissare revisioni riproducibili e adattarli con modifiche minime.

Per una prima release distribuire manualmente i binari verificati. Un eventuale controllo nuove versioni deve essere esplicito o opt-in, usare il repository Sway e non installare codice in background. Futuri aggiornamenti automatici richiedono validazione della firma, protezione da downgrade e sostituzione atomica con rollback.

### Accettazione

Nessuna richiesta ai server Pock all'avvio. Archivi o bundle esterni non vengono eseguiti automaticamente. Una ricerca aggiornamenti fallita non compromette l'app. Il pacchetto contiene tutte le funzioni di base senza download aggiuntivi.

## F11 — Retroilluminazione tastiera (aggiunta richiesta dall'utente)

Controlli meno/più dedicati, con tap a passi di 1/16 e swipe continuo. Tasti larghi come gli altri controlli, icone di luminosità tastiera, feedback visivo alla pressione e valore/errore temporaneo nella zona informazioni.

Usare un adapter isolato CoreBrightness, verificando classe e selettori a runtime; non richiedere privilegi amministratore o installare helper. Riconoscere la tastiera integrata, validare l'intervallo 0–1 e mostrare indisponibilità su hardware non supportato. Non confondere la luminosità della tastiera con quella del display o della Touch Bar.

Preservare la modalità automatica all'avvio. Se il sensore ambientale limita la regolazione, mostrare lo stato e offrire nel menu la scelta esplicita della modalità manuale. Le modifiche dell'utente alla modalità automatica sono intenzionali e non vengono annullate all'uscita. L'attenuazione per inattività viene invece sospesa solo durante l'interazione: salvare lo stato originale e ripristinarlo entro 1,5 secondi dall'ultima regolazione, alla sospensione e all'uscita.

Accettazione: provare aumenti/diminuzioni reali, swipe, estremi, modalità automatica e saturazione, inattività e sleep/wake. Verificare il valore letto dopo una variazione effettiva e il ripristino degli stati temporanei. Non dichiarare il controllo funzionante sulla sola base del risultato positivo del setter.

## F12 — Indicatore nativo macOS a scomparsa

Per volume, muto, luminosità display e tastiera, mostrare il corrispondente indicatore del sistema dopo un comando senza errori. Durante swipe accorpare a20Hz e conservare l'ultimo valore; dissolvenza affidata al sistema, richiesta1000ms. Usare un adapter privato isolato, verificando ABI e disponibilità runtime. Non simulare il popup, non modificare o fermare servizi di sistema. Se il servizio non risponde, la regolazione e il feedback locale devono continuare.

Accettazione: confermare comparsa di finestre del servizio Apple dopo le richieste e assenza dopo dissolvenza; controllare icone e livelli sul dispositivo. Un setter che ritorna successo non prova il rendering. Testare anche muto, tastiera bloccata e swipes rapidi.

## F13 — Tasto Tailscale

Posizione aggiornata: estremo destro, immediatamente dopo volume su. Tasto44×28pt; logo18pt. Logo vettoriale con griglia3×3: nove pallini spenti da disconnesso e cinque pallini accesi a T da connesso. Stato letto dalla CLI locale esistente, nessun daemon aggiunto da Sway.

Al tap riconciliare lo stato reale prima di scegliere connessione o disconnessione. Disabilitare tap concorrenti e confermare il risultato attraverso una nuova lettura. Non assumere successo dal solo codice di uscita; non alterare configurazione, exit node, DNS o routing. Gestire installazione assente, autenticazione necessaria, timeout e stato sconosciuto. Nessun comando automatico di connessione all'avvio o al resume. Mostrare istruzioni locali e aprire Tailscale per l'accesso quando necessario.

Eseguire comandi a argomenti fissi senza shell, senza credenziali e senza privilegi amministrativi. Non registrare output CLI o login URL; non conservare elenchi peer. Aggiornamento15s con tolleranza, sospeso insieme a Sway. Verificare anche timeout, errori, modifica dello stato da un altro client e annullamento del preflight alla sospensione.
