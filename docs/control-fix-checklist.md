# Touch Bar correction checklist

Scope: Sway Touch Bar controls, keyboard backlight and application list only. App targets are now 48 points wide; control symbols use 17-point configuration, capped at 18 points, and app images are 22 points. Reference: pock/control-center-widget, ControlCenterWidget.swift and PressableSegmentedControler.swift, read from upstream on 2026-11-16.

- Native momentary NSSegmentedControl, 64-point segments, system Touch Bar volume/mute template icons and native sun brightness symbols, matching the named Pock reference.
- No custom musical-note text or blue progress underline.
- Direct Touch Bar touches: tap changes one step or toggles mute; swipe adjusts continuously with a native slider; cancel/end clear gesture state; no trailing tap after swipe.
- Windowless processes excluded using window metadata, not Dock membership; refresh when windows open/close without process changes.
- No screen images or titles collected; list changes do not require repaint when membership/focus is unchanged.
- Audio uses virtual main volume with writable-property checks and channel fallback. Brightness adapter includes CoreDisplay.
- Rendered appearance, physical gestures, minimized-window behavior and hardware setters require explicit verification; compilation alone does not establish these.

Only the named reference was compared; no broader UI convention was inferred. Other screens, typography and unrelated widgets were not examined.

## Follow-up correction: display, feedback and keyboard

- DisplayServices takes priority on Apple Silicon. A real requested variation and readback must be measured, rather than only rewriting an unchanged value.
- Direct touch-down selects/highlights the segment immediately. A 120 ms release pulse is isolated by generation so rapid taps do not clear a later highlight.
- Info area displays the reported level/error for one second, with fixed width to prevent moving controls.
- Keyboard backlight uses the runtime-validated KeyboardBrightnessClient ABI. Preserve automatic mode by default; expose an explicit menu toggle for manual adjustment under ambient saturation.
- Temporarily suspend keyboard idle dimming while adjusting; restore exact prior flag within 1.5 seconds after last write, on pause and exit.
- Check physical touch behavior and actual layout after installation; source review does not establish these.

## Icon refinements

- Display decrease uses the filled-center sun.min.fill symbol.
- Battery has continuous proportional fill with adjacent percentage; unknown and charging states remain explicit.
- Info width 190 points; icon size changes do not reduce touch targets.
- AppKit icon render and example text width checks pass; actual Touch Bar alignment remains unevaluated.

## Reopen, native OSD and Tailscale

- Per revised user request, all running regular apps remain visible; tap uses standard reopen without duplicating an application process.
- Native macOS transient indicators for successful volume/display/keyboard adjustments, plus locked keyboard state; latest swipe value retained. No simulated overlay or system-service modifications.
- Tailscale button before display brightness: nine gray dots / T of five lit dots, backend-confirmed state, disabled while busy, fresh status before up/down and confirmation afterward.
- Smaller app images18pt, unchanged48pt targets, light-gray inactive/active backgrounds; remove blue explicitly.
- Flexible app viewport48–230pt accommodates fixed controls; physical layout remains a device check.

## Latest compact layout and diagnostics

-44pt control segments and36×28 app buttons; logo18pt, control symbols16pt.
- Foreground app only: bordered light gray. Other app buttons: no border, black background.
- Tailscale final/rightmost, immediately after audio volume-up.
- Plain up preserves saved preferences; process watchdog remains. Classified errors only, concurrent bounded stderr parsing, no raw login URLs retained.
- Full status/error accessible through “Stato Tailscale…”; failed preflight never sends up/down.

### Layout e personalizzazione (17 novembre 2026)
- [x] Controlli a destra, Tailscale ultimo dopo volume su.
- [x] Data, batteria e ora in gruppo centrato geometricamente.
- [x] App con larghezza adattiva, nessun limite a 230 pt; sfondi e dimensioni compatte preservati.
- [x] Nessuno spazio o messaggio quota ChatGPT.
- [x] Finestra nativa con visibilità, zona, trascinamento ordine, spostamento da pulsanti e ripristino.
- [x] Persistenza locale e migrazione testate; modifica durante pausa non riattiva la barra.
- [x] Probe AppKit: 1004 pt effettivi, circa 422 pt app, centro esatto e nessuna sovrapposizione; finestra ispezionata.
- [ ] Verifica manuale di tocchi/swipe e trascinamento con il nuovo contenitore sulla Touch Bar fisica.

### Correzione swipe e banner nuovi (17 novembre 2026)
- [x] Gestione del trascinamento AppKit oltre ai tocchi diretti; il tracking nativo del segmento non assorbe lo swipe.
- [x] Slider mantiene il gesto e non produce un tap aggiuntivo al rilascio, anche con movimenti accorpati.
- [x] Cancellazione del gesto su distacco/pausa; slider solo visuale escluso da focus e accessibilità.
- [x] Test di interazione con eventi NSWindow e hardware simulato.
- [x] Nuovo endpoint Control Center SystemBanner; vecchio riquadro OSDUIHelper escluso su Tahoe.
- [x] Identificatore tastiera corretto da 8 a 25.
- [ ] Conferma finale dello swipe con il dito sulla Touch Bar fisica.

- [x] Screenshot nativi controllati e comparsa/scomparsa verificata per schermo, volume e luminosità tastiera su macOS 26.6.2.

### Regressione riprodotta sul dispositivo
- [x] Traccia reale directTouch: movimento annullato dopo pochi punti dal contenitore NSScrollView.
- [x] Rimossi i pan recognizer dagli antenati dei controlli; clip semplice e paginazione per zone dense.
- [x] Test separato di eventi directTouch (allTouches vuoto), rilascio e ripresa dopo cancellazione.
- [x] Probe della gerarchia: nessun NSScrollView sopra i controlli; centro e larghezze native verificati.
- [x] Tailscale connesso/disconnesso nella prova dell’utente; icona con quattro pallini accesi nella posizione richiesta.
- [x] Conferma fisica dell’utente dopo la correzione: swipe di volume e luminosità entrambi funzionanti.
