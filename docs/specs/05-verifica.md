# Prestazioni e strategia di verifica

## Obiettivi proposti, da confermare con misure

Misurare build Release su MacBook Pro M1 reale. Non usare risultati Debug come prova delle prestazioni finali.

| Indicatore | Obiettivo iniziale proposto |
|---|---|
| CPU inattiva | Media ≤ 0,5% di un core in 10 minuti, dopo stabilizzazione |
| Memoria | Footprint stabile ≤ 100 MB con moduli base |
| Stabilità memoria | Nessuna crescita monotona in 60 minuti di attività ripetuta |
| Risposta ai gesti | Latenza input→aggiornamento p95 ≤ 50 ms |
| Avvio | Barra operativa entro 2 s dall'avvio processo a caldo |
| Rete con integrazioni spente | Nessuna richiesta in avvio e inattività |

Sono budget di progetto, non prestazioni già ottenute. Distinguere footprint da RSS e specificare la metrica raccolta. Se un budget è irrealistico, documentare misure e motivazione prima di cambiarlo.

## Protocollo

Registrare commit, versione macOS, modello, build, alimentazione e integrazioni abilitate. Stabilizzare per 60 secondi. Misurare idle, swipe continuo, avvio/chiusura app, cambi audio, refresh quota e sleep/wake. Ripetere tre volte le misure principali e riportare mediana e picchi. Confrontare la baseline Pock soltanto se compilabile e utilizzabile sullo stesso ambiente.

Usare Instruments per Time Profiler, Allocations/Leaks e risvegli/energia quando disponibili. Activity Monitor è un controllo rapido, non una prova della latenza delle gesture. Indicare se il tempo è misurato fino al cambio modello, al commit UI o al feedback visivo effettivo.

## Regole di implementazione

Nessun polling delle app se le notifiche coprono il caso. Ora aggiornata al minuto. Batteria a eventi. Gesture con aggiornamenti accorpati. Cache limitate. Operazioni di rete asincrone con cancellazione e backoff. Servizi sospesi quando non necessari. Nessuna shell eseguita a ogni movimento del dito.

## Test automatici utili

- Gesture: distinzione tap/swipe, soglia, cancellazione, clamp e valore finale.
- App: deduplicazione, ordine stabile, filtri e terminazione durante selezione.
- Data/batteria: cambio giorno, dato assente e capacità invalida.
- Quota: parsing di risposte minimali, unità, zero, scadenza, reset e più finestre.
- Sicurezza: rifiuto di input pericolosi se rimangono percorsi d'importazione; redazione dei log; migrazione preferenze.
- Ciclo di vita: start/stop ripetuti e rimozione observer con servizi fittizi.

Le fixture devono essere sintetiche e prive di segreti. Non considerare un mock prova di funzionamento dell'hardware o dell'account reale.

## Matrice manuale

1. Avvio pulito, successivo e al login se abilitato.
2. Tap e swipe reali per volume e luminosità; gesture rapide, interrotte e ai bordi.
3. Audio mute, cambio output e output senza volume software.
4. App aperte, chiuse, minimizzate, nascoste, più finestre e lista lunga.
5. Rete assente, quota scaduta e autenticazione revocata.
6. Alimentatore, wake, blocco/sblocco e cambio applicazione.
7. Permessi negati e successivamente concessi.
8. Sospensione Sway, uscita normale, crash simulato in ambiente di sviluppo e recupero.
9. Layout con formati locali e strumenti di accessibilità disponibili.

## Evidenza richiesta

Per ogni criterio: PASS, FAIL o NON VERIFICATO, procedura e risultato osservato. Separare compilazione, test automatici, simulazione e prova sul dispositivo. Nessuna release definita completa con F08 marcata completata soltanto grazie a dati simulati.
