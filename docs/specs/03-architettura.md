# Architettura proposta

## ADR-001 — Evoluzione nativa di Pock

Stato: proposta tecnica coerente con il requisito di partire vicino all'originale.

Mantenere Swift/AppKit e il minimo bridge Objective-C/C necessario per la Touch Bar. Separare progressivamente servizi e presentazione senza riscrivere l'intera app. Swift consente integrazione diretta con il ciclo di vita macOS; il linguaggio da solo non garantisce consumi bassi.

Rust è una possibile scelta per un componente isolato che richieda elaborazione significativa e sicurezza della memoria. Introduce compilazione, distribuzione e FFI aggiuntive. Go aggiunge un runtime e non è la scelta iniziale per questa utility. C è adatto a bridge limitati ma richiede maggiore attenzione alla memoria. Qualsiasi introduzione deve essere motivata da un profilo riproducibile.

## Confini dei componenti

| Componente proposto | Responsabilità |
|---|---|
| AppLifecycle | Avvio, sospensione, wake, uscita, permessi |
| TouchBarCoordinator | Presentazione della barra e ripristino |
| LayoutModel | Ordine, priorità, spazio e moduli visibili |
| AudioService | Dispositivo, volume e muto |
| BrightnessService | Display integrato e luminosità |
| RunningAppsService | Snapshot e notifiche delle app |
| ClockService | Data e ora locali |
| BatteryService | Stato alimentazione |
| SubscriptionUsageProvider | Fonte della quota, autenticazione e stato |
| SettingsStore | Preferenze versionate |
| LocalDiagnostics | Log locali limitati e redatti |

Sono nomi di progetto proposti, non classi già esistenti.

## Flusso e concorrenza

Servizi di sistema → stato tipizzato → confronto con lo stato precedente → aggiornamento della sola vista interessata. Le azioni UI invocano il servizio, che riconcilia il risultato reale.

Operazioni AppKit sul thread principale; rete e lavoro bloccante fuori dal thread principale. Serializzare gli accessi ai modelli condivisi secondo la versione Swift scelta. Cancellare richieste superate e ignorare risultati associati a un dispositivo o account precedente. Non usare semaphore sul main thread.

Ogni servizio espone stato disponibile/indisponibile/errore e metodi start/stop idempotenti. Errori individuali non fanno cadere l'intera barra.

## Dati persistenti

- Preferenze: UserDefaults nel dominio Sway, schema versionato.
- Segreti: Portachiavi, se l'integrazione li richiede.
- Diagnostica: directory Sway dedicata, nessun segreto.
- Cache quota: solo se utile, con timestamp e nessuna credenziale; mai spacciata per dato aggiornato.
- Nessun database necessario per la prima versione.

## Punti iniziali nel codice ereditato

- `Pock/AppDelegate.swift`: avvio, menu e inizializzazione AppCenter.
- `Pock/AppController.swift`: coordinamento, aggiornamenti e telemetria.
- `Pock/UI/TouchBar/`: presentazione e composizione.
- `Pock/Private/TouchBarHelper.swift`: API private e operazioni di sistema.
- `Pock/Widgets/`: caricamento e installazione di bundle.
- `Pock/Network/Services/`: download e aggiornamenti.
- `Podfile`: PockKit, AppCenter, Magnet e Zip.

Prima di cambiare il sistema di dipendenze, ottenere una build baseline. Eliminare dipendenze inutilizzate e fissare le versioni rimanenti. Registrare lockfile nel repository: attualmente `Podfile.lock` è ignorato. Valutare Swift Package Manager soltanto se semplifica davvero le dipendenze rimaste.
