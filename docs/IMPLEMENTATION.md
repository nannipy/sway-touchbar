# Sway — stato implementazione

> Diario storico di sviluppo: le sezioni successive aggiornano e possono superare quelle iniziali. Per lo stato corrente, i requisiti e le istruzioni pubbliche leggere [README italiano](../README.it.md) o [English README](../README.md).

## Target Sway

Il target iniziale è in `Sway/`, compilato da `scripts/build-sway.sh` direttamente con Swift/AppKit. Non usa CocoaPods, PockKit, AppCenter, Zip, servizi Pock o caricamento di widget esterni. I sorgenti upstream restano nel repository come riferimento storico e non fanno parte di questo eseguibile.

Il bridge della presentazione Touch Bar deriva dalle dichiarazioni di Pock. La luminosità è isolata in un adapter opzionale del framework privato DisplayServices. La disponibilità effettiva di entrambi deve essere verificata su macOS di destinazione.

## Build locale

Prerequisito: Xcode installato con licenza già accettata dall'utente. Eseguire dalla radice:

```sh
bash scripts/build-sway.sh
bash scripts/test-sway.sh
open build/Sway.app
```

Il pacchetto viene firmato ad hoc per uso locale. Non è una firma Developer ID e non costituisce una release notarizzata. L'identificatore `dev.sway.touchbar` è provvisorio. L'architettura segue la toolchain host; ARM64 richiede build sul Mac Apple Silicon.

## Funzioni compilate, ancora da verificare sulla Touch Bar

- Processo accessorio e menu Sway con mostra, sospendi/riprendi, stato e uscita.
- Presentazione Touch Bar con zona app scorrevole, data/ora/batteria e controlli.
- Volume CoreAudio, cambio dispositivo, muto e gesture tap/swipe.
- Luminosità integrata tramite adapter dinamico; indisponibile se le API non rispondono.
- App aperte, icone, evidenziazione dell'app attiva e attivazione al tap.
- Batteria a notifiche e orologio aggiornato al minuto.
- Nessuna rete e nessuna diagnostica persistente nel target Sway.
- Test logici delle gesture eseguiti con esito positivo (soglia, clamp, assenza di salto iniziale e larghezza zero).

## Verifiche del 16 novembre 2026

Dopo l'accettazione della licenza Xcode da parte dell'utente:

- Build ottimizzata ARM64: PASS.
- Test logici gesture: PASS.
- Firma ad hoc verificata con codesign: PASS.
- Info.plist e sintassi degli script: PASS.
- Avvio nella sessione grafica macOS: eseguito; processo Sway osservato attivo.
- Librerie collegate: framework macOS e runtime Swift di sistema, nessun SDK esterno.
- Verifica grafica automatica: NON VERIFICATA, timeout del servizio computer use.
- Funzioni sulla Touch Bar, sleep/wake e prestazioni di lungo periodo: NON VERIFICATE.

Il primo avvio nel sandbox ristretto non è riuscito; l'esecuzione nella sessione macOS esterna al sandbox è rimasta attiva. Una lettura istantanea di CPU/memoria non viene trattata come benchmark.

## Lavoro residuo

- Proseguire correzioni e test funzionali su hardware reale.
- Verificare scorrimento e allocazione spazio Touch Bar, tap/swipe, wake e disponibilità API private.
- Gestire volume per dispositivi con sole proprietà per canale, verificare scrivibilità e notifiche anche per canale; attualmente si usa il canale principale.
- Aggiornamento luminosità da modifiche esterne: oggi avviene al minuto o al wake; serve una strategia più tempestiva e misurata.
- Preferenze persistenti, avvio al login opt-in e configurazione moduli.
- Provider quota ChatGPT/Codex reale: al momento soltanto stato “non disponibile”, nessun dato simulato.
- Audit completo dei sorgenti upstream separato dal perimetro del nuovo eseguibile.
- Benchmark CPU/memoria e test di accessibilità.
- Fork GitHub, CI e release pubblica dopo ripristino autenticazione e validazione.

L'implementazione costituisce un primo incremento compilato e parzialmente verificato; non completa la specifica.

## Correzioni dopo prova utente — 16 novembre 2026

Problemi riportati: app senza finestre presenti nella barra, controlli non reattivi e aspetto distante da Pock.

Correzioni:
- La lista incrocia i processi con i proprietari di finestre CGWindow a livello normale, con dimensioni valide e alpha positivo. Nessuna lettura di immagini o titoli. Riconciliazione ogni 2 secondi con tolleranza, nessuna ricostruzione delle icone se membri/focus sono invariati. Finestre minimizzate/nascoste e comportamenti tra Spaces restano da verificare sul dispositivo.
- Rimosso il controllo disegnato che gestiva soltanto mouseDown/mouseDragged/mouseUp: la Touch Bar usa eventi di tocco diretto. Ora NSSegmentedControl gestisce touchesBegan/Moved/Ended/Cancelled, identità del dito iniziale e applicazione del valore finale. Slider NSSlider nativo durante il trascinamento.
- Aspetto riferito a pock/control-center-widget revisione d27ce2b11981329475251448af04b81441217965: segmenti momentanei da 50 punti, icone Touch Bar native volume/muto e simboli di sole per luminosità; nessuna nota musicale o linea blu personalizzata.
- Audio: volume principale virtuale come Pock, controllo scrivibilità e fallback sui canali; muto con proprietà disponibile oppure salvataggio/ripristino del livello. Il fallback per canali non preserva ancora un eventuale bilanciamento stereo personalizzato.
- Luminosità: aggiunto CoreDisplay come nel widget originale; lettura e scrittura usano lo stesso backend validato. API private sempre da verificare sulla versione macOS.

Verifiche: build ARM64 e test gesture/filtro finestre PASS. Probe locale: volume 0,375 letto e riscritto senza errori, readback invariato; luminosità 1,0 letta e riscritta, readback invariato. Questa prova non dimostra la variazione fisica del livello o la consegna delle gesture. La revisione indipendente del codice ha individuato e fatto correggere fallback, filtro trasparenza, touch identity e ultimo valore dello swipe; verifica visiva/hardware ancora aperta.

## Display, keyboard and press feedback — follow-up

The display backend now prefers DisplayServices. A real hardware probe changed brightness from 0.77863747 to 0.65363753, then restored 0.77863747. This replaces the earlier inconclusive same-value check.

Keyboard backlight controls were added through a small Objective-C CoreBrightness adapter, with runtime checks for private selectors. The client ABI was inspected on this Mac. Ambient saturation and idle dimming were reproduced: commands could report success while the backlight stayed at zero. With manual mode and temporary suspension of idle dimming, the production service changed the reported backlight from 0 to 0.125 and restored 0. The original automatic-mode flag was restored after the diagnostic.

Usage: new keyboard-light down/up segments support tap and swipe. If macOS limits the level due to ambient light, the info area reports the limit. In the Sway menu, uncheck “Luminosità tastiera automatica” to choose manual mode. Sway never changes automatic mode at launch or merely from a brightness tap. Idle dimming is suspended only for interaction and restored 1.5 seconds after the last adjustment, on pause and on exit.

All control segments are 64 points wide (previously 50); app buttons are 48 points wide (previously 32). Direct touches highlight immediately, with a short release pulse; adjustment results briefly replace the info text. The Touch Bar's physical height remains fixed. Info width is fixed at 160 points to keep result messages from moving controls.

Build and gesture/window-filter tests pass. An independent source review found no remaining blocking issue in this correction. Physical press highlighting, slider feel, and fit on the Touch Bar still require user verification.

Reference for the DisplayServices priority: [Hammerspoon screen implementation](https://github.com/Hammerspoon/hammerspoon/blob/master/extensions/screen/libscreen.m). Keyboard selector signatures were verified against the installed runtime rather than assumed from external bindings.

## Icon refinement — 17 novembre 2026

As requested, control symbols are configured at 17 points and fitted within an 18-point maximum dimension; application icons are 22 points. Touch targets stay at 64 points per segment and 48 points per application. The display decrease icon uses `sun.min.fill`, with a filled center.

The status now contains a vector battery outline with continuous proportional fill and adjacent percentage, retaining a charging marker. Unknown charge displays an empty outline with a dash and unknown percentage, not a false zero. The status area is 190 points wide. A native AppKit render probe successfully materialized unknown/0/1/50/100% icons, verified availability of sun.min.fill, and measured 160.32 points for a date/time plus charging 100% example. Hardware alignment and full Touch Bar fit remain subject to actual-device review.

Build, existing gesture/window tests and source review pass. Temporary feedback updates its accessibility label as well as displayed text.

## Reopen, system indicators and Tailscale — 17 novembre 2026

The user changed the app-list requirement: include all regular running applications, including those with no windows. Tapping sends the standard Launch Services reopen request through NSWorkspace.openApplication, with activation and without requesting a new instance. Each app controls its own reopen behavior. A fixture initially without windows received reopen and created a visible window. The previous two-second window poll has been removed; NSWorkspace notifications drive membership/focus updates.

Native feedback uses the installed Apple OSD service. The OSDManager selector ABI was inspected on this Mac. On macOS 26, manager calls accepted the message but produced no indicator; the implementation therefore addresses the nonprivileged com.apple.OSDUIHelper XPC service on macOS 26+, without changing or restarting system services. Earlier versions use OSDManager. Native on-screen OSDUIHelper windows were observed after requests for screen, volume and keyboard indicators, and were absent after fade in all three checks. Displayed icons/visual fidelity have not been independently captured. Swipe requests coalesce at 20 Hz, keeping the last value; the system owns drawing and fade. Errors remain visible locally in the Touch Bar.

Tailscale button: before display brightness; nine gray dots when disconnected, five illuminated dots forming a T when the daemon confirms Running. Busy operations disable the button. The service reads the existing CLI locally every 15 seconds with tolerance and reconciles immediately before a toggle. User taps alone issue up --timeout=8s or down; there are no auth keys, --reset, exit-node or routing changes in Sway. Existing Tailscale configuration is retained. If login or confirmation is needed, use the existing Tailscale app. CLI output is not logged or persisted; peer listing is disabled and errors are generic to avoid exposing login URLs or network metadata. Commands run asynchronously, without a shell or administrator elevation, with bounded duration. Pausing cancels monitoring and a not-yet-issued toggle; it does not disconnect an existing VPN or undo a command already sent.

Production read-only status test: Tailscale CLI found in /Applications/Tailscale.app; disconnected state confirmed. Simulated tests verify status parsing, connect/disconnect commands, fresh-state decisions, no optimistic connected state, duplicate-tap prevention, command failure and preflight cancellation. No live VPN up/down was performed during implementation; that remains a device interaction test.

App icons are now 18 points, with light-gray backgrounds and no blue active bezel. Their touch targets remain 48 points. The app viewport can compress from 230 down to 48 points to accommodate the extra fixed control.

Reproducible checks: bash scripts/test-sway.sh for logic/icon tests; bash scripts/test-integration.sh for read-only Tailscale status, native HUD appearance/fade metadata and a temporary reopen fixture. Integration probes require a graphical macOS session; they show transient system indicators and a temporary test window. Private OSD compatibility and final Touch Bar layout remain OS/device-specific.

CLI reference: https://tailscale.com/docs/reference/tailscale-cli. No Tailscale library or code from external projects is bundled.

## Compact buttons and Tailscale diagnostics — 17 novembre 2026

All control segments are now44 points wide; app targets are36×28 with18-point images. Tailscale is44×28 with an18-point logo and is the final item, directly after volume up. Only the foreground app has a light-gray bordered background (white0.9); inactive app buttons are borderless over the black Touch Bar background.

Tailscale diagnosis was read-only: version1.104.6 installed, backend Stopped, WantRunning false and LoggedOut false. The old generic message was “operazione non confermata”, not proof of missing configuration; raw CLI errors were discarded by that implementation, so the exact preceding failure cannot be reconstructed.

Connection now uses plain tailscale up, rather than adding --timeout, following the upstream no-flags contract that preserves existing preferences. The process watchdog still bounds execution. This is a compatibility fix, not proof that the previous flag caused the reported failure. No API token or password is consumed by Sway; the existing local Tailscale profile is used. A live connection attempt remains unverified.

The runner drains stderr concurrently, retains at most8192 bytes only temporarily for classification, and exposes only a sanitized category. It never logs raw error output or login URLs. Failures distinguish settings confirmation, access denied, login, unavailable service, watchdog timeout and unknown failure; a failed initial status propagates its category without issuing up/down. The “Stato Tailscale…” menu shows the current state and full last operation message, avoiding truncation in the Touch Bar.

Tests include failure categories and verification that access-denied preflight does not issue a control command. If the next user tap still fails, the full message from “Stato Tailscale…” is the next necessary diagnostic; credentials are not needed.

No-flags behavior reference: https://github.com/tailscale/tailscale/blob/main/cmd/tailscale/cli/up.go (command help). Native layout remains subject to device review.

## Layout personalizzabile — 17 novembre 2026

- La barra usa un unico contenitore nativo con tre zone indipendenti. Predefinito: app a sinistra; data, batteria con percentuale, ora al centro; luminosità display, luce tastiera, volume/muto, Tailscale a destra.
- Il centro del gruppo centrale coincide con la metà del contenitore, indipendentemente dalla larghezza dei controlli. Le zone laterali scorrono in caso di eccesso di elementi, senza sovrapporsi. Il vecchio limite di 230 pt delle app è rimosso; le app occupano tutto lo spazio disponibile nella propria zona.
- Finestra **Sway → Personalizza Sway…**: caselle Mostra, selettori Sinistra/Centro/Destra, trascinamento delle righe e pulsanti Sposta su/giù, Ripristina layout. Volume e luminosità restano gruppi per preservare swipe e muto.
- Modifiche applicate subito e salvate localmente con UserDefaults (`sway.barLayout.v1`), senza rete. Caricamento tollerante a ID futuri/sconosciuti, righe duplicate e nuove funzioni. Nessun campo quota ChatGPT e nessuno spazio riservato.
- I messaggi delle azioni sono consultabili nel menu Sway e nel tooltip; non sostituiscono più data/batteria/ora. HUD di sistema invariati.
- Verifica: test modello/layout/salvataggio/migrazione; compilazione; probe AppKit nella sessione grafica. Larghezza effettiva del contenitore 1004 pt e zona app circa 422 pt nel layout predefinito, centro geometrico e bordo destro verificati, configurazioni nascoste/dense verificate. Finestra nativa acquisita e ispezionata. Non sono stati simulati tocchi fisici o trascinamenti dell’utente sulla Touch Bar.
- Test ripetibile della UI: dopo `bash scripts/build-sway.sh`, `bash scripts/test-layout-ui.sh` in una sessione grafica con accesso alla Touch Bar. Mostra temporaneamente la barra e la finestra di prova; non modifica hardware, VPN o preferenze salvate. Riavviare Sway dopo la prova per ripresentare la barra normale.

## Slider e nuovi banner macOS — 17 novembre 2026

- `AdjustmentView` ora gestisce sia gli eventi mouse/trascinamento di AppKit sia i tocchi diretti. L’override di mouseDown evita il ciclo di tracking di NSSegmentedCell, che assorbe i movimenti prima dello slider. Entrambi i percorsi condividono inizio, aggiornamento, rilascio e cancellazione; una sola sorgente può gestire il gesto.
- Lo slider visuale non intercetta il puntatore, non riceve focus ed è escluso dall’accessibilità. I segmenti restano azionabili come prima. Lo spostamento finale viene riconosciuto anche se AppKit accorpa gli eventi intermedi; nessun tap aggiuntivo al rilascio. Nascondere/spostare il controllo o sospendere Sway annulla la sessione, evitando blocchi al gesto successivo.
- Su macOS 26 i popup passano al servizio Apple `com.apple.SystemBanner` di Control Center tramite il protocollo OSD compatibile. Il precedente endpoint `com.apple.OSDUIHelper` mostrava il vecchio riquadro centrale. Nessuna finestra HUD disegnata da Sway, nessuna modifica ai servizi o richiesta di privilegi amministrativi nell’app. Su macOS precedenti resta OSDManager.
- Corretto anche l’identificatore tastiera: 25 (luminosità tastiera), mentre 8 indicava `discreteBrightnessAlt` e non la tastiera. Confermato con il protocollo storico di [NewBezelServices](https://github.com/MLforAll/NewBezelServices/blob/master/XPC/image_ids.txt) e con la visualizzazione nativa locale.
- Nuova prova `bash scripts/test-controls-ui.sh`: eventi attraverso NSWindow.sendEvent, trascinamento continuo, inversione, swipe accorpato, rilascio senza tap aggiuntivo, tap ±, muto e ripresa dopo distacco; hardware simulato. Non equivale a un test con il dito sulla Touch Bar fisica.
- `Tests/HUDProbe.swift` distingue i popup dal PID reale di Control Center, verifica assenza del vecchio OSDUIHelper, comparsa/scomparsa e acquisisce immagini native. Le sole richieste mostrano i valori correnti, senza modificare volume, luminosità o VPN. Le API restano private e dipendenti dalla versione di macOS.

Esito finale: i tre probe HUD passano su macOS 26.6.2, con screenshot nativi controllati per Schermo, Altoparlanti MacBook Pro e Luminosità tastiera e assenza del vecchio OSD. La prova attende fino a 8 secondi per la scomparsa: gli aggiornamenti automatici del sistema possono prolungare il banner oltre il fade richiesto. Eseguire senza interazioni simultanee sulla barra. Probe di interazione AppKit passato anche nella sessione grafica; build e firma ad hoc verificate. Rimane la conferma manuale del gesto con il dito sul dispositivo fisico.

## Avvio come applicazione macOS — 17 novembre 2026

Sway ora è una normale applicazione AppKit (`activationPolicy = regular`, senza LSUIElement), con icona nel Dock, menu applicazione e menu Finestra. All’apertura mostra Personalizza Sway. Aprirla nuovamente dal Dock/Finder richiama la stessa finestra; chiuderla lascia attivi Touch Bar e menu Sway. Comandi standard: ⌘, personalizzazione, ⌘W chiudi finestra, ⌘M contrai, ⌘H nascondi, ⌘Q esci.

Il pacchetto contiene Sway.icns, generata da un segno vettoriale locale senza download. `scripts/install-sway.sh` compila e installa in `/Applications/Sway.app` (o in una destinazione Sway.app esplicita), verifica l’identità di eventuali app preesistenti e registra l’app in Launch Services. L’installazione richiede Sway chiusa; prepara e verifica una copia nuova prima di sostituire la precedente, con ripristino in caso di errore nello spostamento. Le preferenze locali restano esterne al bundle.

Verifica: build, firma e Info.plist; probe AppKit di apertura, chiusura senza terminazione, riapertura e riuso di una sola finestra. Nessuna configurazione di avvio automatico all’accesso è stata aggiunta.

## Swipe fisico: annullamento da NSScrollView — 17 novembre 2026

La prova fisica dell’utente ha riprodotto il difetto che i precedenti test mouse non vedevano: gli eventi directTouch iniziano e si muovono di pochi punti, poi arrivano a `touchesCancelled` prima del rilascio. Gli NSScrollView esterni delle tre zone intercettavano il movimento con il proprio riconoscitore pan, anche quando non serviva scorrere.

- Le zone ora usano `ControlBandView`: NSClipView semplice, senza riconoscitore pan sui controlli. I layout personalizzati troppo densi hanno frecce di paginazione; lo scorrimento per le icone delle app resta confinato al loro NSScrollView interno.
- Gli eventi diretti vengono letti con `touches(matching:in:)`; `allTouches` è dichiarato dall’SDK per NSEventTypeGesture. La fixture di regressione restituisce volutamente un insieme vuoto per allTouches e verifica trascinamento, rilascio, tap successivo e recupero dopo cancellazione.
- Il probe di layout verifica inoltre che luminosità, tastiera, volume e Tailscale non abbiano NSScrollView tra i propri antenati. Geometria nativa 1004 pt, centro e zona app circa 422 pt confermati.
- Diagnostica opzionale con argomento `--diagnose-touch`: log locale `dev.sway.touchbar`, categoria `controls`, solo fasi/coordinate dei controlli e stati VPN sanitizzati. Nessuna registrazione dei tasti digitati, indirizzi di rete o account; disabilitata negli avvii normali. Lettura di sviluppo con `log show --info`.
- Durante la prova fisica Tailscale ha eseguito con successo connessione e disconnessione, confermate sia dall’utente sia dalle transizioni di stato. Nessuna modifica di credenziali o profilo. L’icona connessa ora accende quattro punti: tre nella seconda riga e uno sotto al centro; test pixel verificato.

Conferma finale sul dispositivo: l’utente ha provato volume e luminosità e ha confermato che entrambi gli swipe funzionano. Terminata la diagnostica, Sway è stata riaperta normalmente dalla copia installata in Applicazioni.

## Margini percentuale e sfondo app — 17 novembre 2026

Aggiunto margine reale al campo percentuale: metriche arrotondate verso l’esterno, 4 pt aggiuntivi nel testo e 2 pt liberi a destra nel contenitore. Il centro resta geometrico. L’area delle app ora è alta 30 pt come il documento, anziché 28; i pulsanti da 28 pt sono centrati. Lo sfondo dell’app attiva è disegnato con bordo arrotondato all’interno del pulsante (inset 1 pt orizzontale, 2 verticale), eliminando il debordo del bezel nativo. Icone da 18 pt, grigio chiaro attivo e nero inattivo preservati; nessuna modifica agli eventi o ai servizi.

Verificati build e probe AppKit nativo. Screenshot della Touch Bar controllato con fixture 100% in carica e prima app evidenziata: simbolo percentuale completo e contorno arrotondato visibile anche sopra. La fixture non cambia batteria, stato delle app o preferenze del sistema.


## Solo barra dei menu — 17 novembre 2026

Su richiesta dell’utente Sway torna a `activationPolicy = accessory` con `LSUIElement = true`: niente icona nel Dock, menu Sway sempre disponibile nella barra dei menu. Il bundle resta installato in Applicazioni ed è apribile da Finder/Spotlight. Finestra di personalizzazione, riapertura, Touch Bar e servizi invariati.
