# Piano di implementazione

Tutte le attività sono future. Nessuna modifica applicativa è inclusa nella presente consegna documentale.

## P0 — Baseline e inventario

- [ ] Confermare Mac di test, versione macOS e toolchain Xcode.
- [ ] Registrare revisione upstream e stato Git; preservare modifiche esistenti.
- [ ] Inventariare PockKit, widget e dipendenze transitive con licenze.
- [ ] Tentare build baseline e documentare ostacoli riproducibili.
- [ ] Rilevare comportamento e consumi iniziali, se eseguibile.
- [ ] Preparare registro dei problemi di sicurezza verificati.

Uscita: ambiente riproducibile oppure elenco preciso dei blocchi; nessuna esecuzione di bundle scaricati senza verifica.

## P1 — Identità e build Sway

Dipende da P0.

- [ ] Applicare nome Sway a bundle e interfaccia.
- [ ] Separare identificatori e percorsi dati da Pock.
- [ ] Ottenere build ARM64 locale; verificare dipendenze native.
- [ ] Fissare versioni e lockfile.
- [ ] Documentare comandi effettivamente provati e schema Xcode.

Uscita: build locale avviabile, senza collisioni con Pock.

## P2 — Privacy e superficie di attacco

Dipende da P1; audit può iniziare in P0.

- [ ] Rimuovere telemetria e configurazioni correlate.
- [ ] Applicare la decisione sui widget integrati o documentare l'alternativa.
- [ ] Disattivare download e aggiornamenti upstream.
- [ ] Rimuovere elevazione e percorsi obsoleti non necessari.
- [ ] Correggere dipendenze vulnerabili applicabili.
- [ ] Introdurre diagnostica locale controllata.
- [ ] Verificare traffico e percorsi alternativi di installazione.

Uscita: checklist sicurezza con risultati e limiti, nessun invio remoto inatteso.

## P3 — Controlli fondamentali

Dipende da P2.

- [ ] Creare servizi audio e luminosità isolati.
- [ ] Implementare motore gesture comune e testarlo.
- [ ] Implementare F03 e F04 con indisponibilità esplicita.
- [ ] Comporre layout con spazio fisso e zona flessibile.
- [ ] Provare hardware M1, cambi dispositivi e sleep/wake.

Uscita: tap e swipe verificati sul dispositivo, senza conflitti o privilegi amministrativi.

## P4 — Moduli informativi e preferenze

Dipende da P3.

- [ ] Implementare F05 app aperte con notifiche e cache limitata.
- [ ] Implementare F06 data/ora e F07 batteria.
- [ ] Completare preferenze, permessi contestuali e avvio opt-in.
- [ ] Verificare layout lungo, localizzazione e accessibilità.

Uscita: funzioni locali complete e misure iniziali entro budget o scostamenti documentati.

## P5 — Quota ChatGPT/Codex

La ricerca di fattibilità può iniziare in P0. L'integrazione UI dipende da P4.

- [ ] Identificare fonte affidabile e condizioni d'accesso.
- [ ] Registrare decisione tecnica e limiti del dato.
- [ ] Implementare provider, autenticazione, cache e backoff.
- [ ] Implementare stati e selezione finestra.
- [ ] Testare errori con fixture e verificare dati con account reale.

Uscita: quota attendibile oppure blocco esplicito con funzione non disponibile. Un'eventuale prima release delle funzioni locali deve dichiarare questa incompletezza.

## P6 — Verifica e pubblicazione

Dipende da P1–P4 e dallo stato documentato di P5.

- [ ] Eseguire test mirati, build Release e matrice manuale.
- [ ] Profilare CPU, memoria, gesture e traffico.
- [ ] Completare documenti utenti, contributori e sicurezza.
- [ ] Ripristinare autenticazione GitHub e confermare proprietario/URL.
- [ ] Creare fork pubblico conservando storia e attribuzione.
- [ ] Controllare contenuti del diff e assenza di segreti prima del push.
- [ ] Pubblicare sorgente; pubblicare binari soltanto dopo verifica separata del pacchetto e della firma prevista.

Uscita: repository pubblico navigabile, istruzioni riproducibili, risultati dei test e limiti noti. Non usare il nome di una release Pock per presentare un binario Sway.

## Gestione del lavoro

Un cambiamento verificabile per commit o PR: rimozione telemetria, sicurezza import, volume, luminosità, lista app, moduli di stato, quota, profiling. Evitare di mescolare un cambio di linguaggio con modifiche funzionali. Ogni PR riporta requisito coperto, comportamento, verifiche e limitazioni.

## Definizione di completamento

Un requisito è completato quando è implementato, documentato e verificato al livello necessario. Il progetto complessivo resta incompleto rispetto alla richiesta originale se la quota reale non è disponibile, anche se una release locale può essere utilizzabile. Nessuna casella si spunta sulla sola base della compilazione.
