# Sway — specifiche e piano di realizzazione

> Specifica originale conservata per tracciabilità, inclusi requisiti futuri o superati. Lo stato corrente è nei [README](../../README.md). Pubblicazione confermata: fork pubblico `nannipy/sway-touchbar`; hardware verificato MacBook Pro con Apple M1.

Versione documentale: 1.0, 16 novembre 2026. Stato: specifica di progetto, applicazione non implementata né verificata come Sway.

Questi file sono istruzioni per una successiva implementazione. In questa attività si modifica esclusivamente documentazione testuale. Nessuna voce del piano equivale a una funzionalità già disponibile.

## Percorso di lettura

1. [Prodotto e requisiti](01-prodotto.md): obiettivi, vincoli e ambito.
2. [Funzioni e interazioni](02-funzioni.md): comportamento, implementazione e accettazione per ogni funzione.
3. [Architettura](03-architettura.md): componenti, dati, concorrenza e dipendenze.
4. [Sicurezza e privacy](04-sicurezza.md): audit, minacce e correzioni.
5. [Prestazioni e verifica](05-verifica.md): misure, test e verifiche sul dispositivo.
6. [Piano di lavoro](06-piano.md): fasi, dipendenze e condizioni di completamento.
7. [Documentazione operativa](07-operativita.md): sviluppo, installazione, rilascio e manutenzione.

## Convenzioni

- **Confermato**: richiesto o scelto dall'utente.
- **Default proposto**: scelta operativa da adottare inizialmente, modificabile senza cambiare l'obiettivo.
- **Da validare**: dipendenza tecnica o comportamento non ancora dimostrato.
- I criteri di accettazione sono condizioni future, non risultati di test.

## Tracciabilità

| ID | Requisito | Specifica | Fase |
|---|---|---|---|
| F01 | Identità Sway e avvio | Funzioni § F01 | P1 |
| F02 | Layout persistente | Funzioni § F02 | P3 |
| F03 | Volume, muto e swipe | Funzioni § F03 | P3 |
| F04 | Luminosità e swipe | Funzioni § F04 | P3 |
| F05 | Applicazioni aperte | Funzioni § F05 | P4 |
| F06 | Data e ora | Funzioni § F06 | P4 |
| F07 | Batteria | Funzioni § F07 | P4 |
| F08 | Quota ChatGPT/Codex | Funzioni § F08 | P5 |
| F09 | Preferenze e diagnostica | Funzioni § F09 | P2–P4 |
| F10 | Aggiornamenti e widget | Funzioni § F10 | P2 |
| F11 | Retroilluminazione tastiera | Funzioni § F11 | Incremento controlli |
| F12 | Indicatore nativo a scomparsa | Funzioni § F12 | Incremento feedback |
| F13 | Tasto Tailscale | Funzioni § F13 | Incremento controlli |
| SEC | Nessuna telemetria e sicurezza | Sicurezza | P0–P6 |
| PERF | Leggerezza | Prestazioni e verifica | P0–P6 |

## Decisioni ancora aperte

- Identificatore bundle definitivo e account GitHub proprietario del fork; `nannipy` risulta configurato localmente, ma non è una conferma dell'account di pubblicazione.
- Versione minima di macOS: iniziare dalla versione del Mac di destinazione, ampliare soltanto dopo test.
- Compatibilità con widget esterni: per la prima versione si propone un insieme integrato controllato; non è una decisione già confermata dall'utente.
- Fonte affidabile della quota dell'abbonamento e modalità di autenticazione.
- Firma Developer ID e notarizzazione per eventuali binari pubblici.
