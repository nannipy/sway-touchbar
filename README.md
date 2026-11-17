# Sway Touch Bar

**Experimental alpha · macOS · Swift / AppKit · MIT**

[Italiano](README.it.md)

Sway is a personal, open-source fork of [Pock](https://github.com/pock/pock): a native Touch Bar companion with running apps, system controls and a layout you can customize. It lives in the menu bar, without a Dock icon.

![Sway running on a MacBook Pro Touch Bar](docs/images/touch-bar.png)

> **Compatibility verified only on a MacBook Pro with Apple M1 (MacBookPro17,1), running macOS 26.6.2 (built with Xcode 27.2).** Other hardware and macOS versions are unverified. This is an experimental project, not a stable Pock release or an official Pock product.

## Features

- **Running apps:** small icons for regular running applications, with a light gray highlight for the foreground app and black backgrounds for the others. Tap to activate or send the app its normal macOS reopen request, including when it has no windows. Whether a new window opens is up to that application.
- **Volume:** tap down/up, tap mute, or swipe continuously across the control.
- **Display brightness:** tap down/up or swipe to adjust the built-in display.
- **Keyboard backlight:** tap or swipe, with an explicit automatic/manual setting for ambient-light restrictions.
- **Native feedback:** fading macOS indicators for volume, display and keyboard brightness. On macOS Tahoe, Sway invokes the new Control Center banners.
- **Battery, date and time:** proportional battery fill, percentage and charging state. The center group stays geometrically centered in the available Touch Bar area.
- **Tailscale:** toggle an existing local connection. Nine dim dots indicate disconnected; four lit dots form a T when connected.
- **Custom layout:** show/hide elements, move them between left/center/right, and reorder them by dragging or with move buttons. Preferences are saved locally.
- **Menu bar controls:** open customization, pause/resume the bar, inspect Tailscale status, adjust keyboard automatic brightness, or quit.

Default layout:

| Left | Center | Right |
| --- | --- | --- |
| Running apps | Date · Battery · Time | Display · Keyboard · Volume / Mute · Tailscale |

Apps use the space available on their side and can scroll horizontally. Control groups keep their swipe gestures; dense custom arrangements use paging arrows instead of placing a scrolling gesture over the controls.

## Requirements

- A Mac with a **physical Touch Bar**. Sway does not provide a replacement bar on a Mac without one.
- Xcode and its command-line tools, with first-launch setup and license acceptance completed.
- The build currently targets macOS 13.0 and later, but **the deployment target is not a compatibility guarantee**: only the M1/macOS configuration above has been verified.
- Optional: an installed, signed-in [Tailscale](https://tailscale.com/) client for the VPN button.

No CocoaPods, Homebrew packages, paid Apple Developer account or external Swift dependencies are required to build Sway. The inherited Pock Xcode project and Podfile are historical source; use the scripts below for Sway.

## Build from source

```sh
git clone https://github.com/nannipy/sway-touchbar.git
cd sway-touchbar
bash scripts/build-sway.sh
open build/Sway.app
```

The script builds an optimized app for the host architecture, creates its icon and applies a local ad hoc signature. The result is `build/Sway.app`.

This repository distributes **source and build instructions only**. There are no downloadable Sway app releases, Developer ID signatures or notarized binaries. Build on the Mac where you intend to use it; architectures other than the tested ARM64 configuration remain unverified.

If Xcode reports that its license or initial setup is incomplete, open Xcode and complete those steps before rebuilding. If `xcrun` selects the wrong developer directory, check `xcode-select -p` and select your installed Xcode toolchain.

## Install and update

Quit any running Sway instance before installing. For your user account:

```sh
bash scripts/install-sway.sh "$HOME/Applications/Sway.app"
open "$HOME/Applications/Sway.app"
```

Or install to the shared Applications folder, if your account can write there:

```sh
bash scripts/install-sway.sh
open /Applications/Sway.app
```

The installer builds a fresh bundle, verifies its signature, checks that an existing destination belongs to Sway, and replaces it without merging obsolete bundle files. It registers the app with Launch Services. Your layout preferences are stored outside the app and survive an update.

You can then open Sway from Finder or Spotlight. It appears **only in the menu bar**. Opening the app shows customization; closing that window keeps the Touch Bar active. Use the **Sway → Esci da Sway** menu item to quit. Automatic launch at login is not implemented.

## Customize and use

The app's own interface currently uses Italian labels; the README is available in both languages.

1. Open **Sway → Personalizza Sway…** in the menu bar.
2. Use **Mostra** to show or hide an element.
3. Choose **Sinistra**, **Centro** or **Destra** for its position.
4. Drag rows or use **Sposta su / Sposta giù** to change their order within a zone.
5. Use **Ripristina layout** to restore the default arrangement.

Changes apply immediately. Volume, display and keyboard brightness remain grouped controls so that swiping still works. Tap `−/+` for steps; keep your finger on the Touch Bar and move horizontally for continuous adjustment. The middle volume segment toggles mute.

Keyboard brightness can be limited by the ambient-light sensor. The menu's **Luminosità tastiera automatica** setting explicitly switches automatic mode; Sway does not silently disable it on launch. It temporarily suspends idle dimming during manual interaction and restores the prior idle-dimming state afterwards.

### Tailscale

Install and sign in to Tailscale first. Sway searches for its local CLI in:

- `/Applications/Tailscale.app/Contents/MacOS/Tailscale`
- `/opt/homebrew/bin/tailscale`
- `/usr/local/bin/tailscale`

The button reads the current state before choosing `up` or `down`, then checks the result. Connection uses plain `up`, preserving existing preferences. Sway does not ask for auth keys, reset the profile or choose an exit node. Pausing or quitting Sway does not disconnect Tailscale.

For failures, open **Sway → Stato Tailscale…** for a sanitized local status message. First verify that the official Tailscale app can connect normally.

## Privacy and security scope

The standalone Sway executable has no analytics SDK, remote crash reporting, remote widget downloads or automatic updater. Layout preferences remain on your Mac. Optional touch diagnostics are local and disabled during normal launches.

Tailscale remains a separate, networked application: Sway invokes its installed CLI to read status and respond to your connection commands. Its state is polled periodically while Sway is active. Sway itself does not add a remote telemetry endpoint.

The repository retains Pock's original source and history, including integrations that **are not compiled into Sway**. Their presence does not mean they have all been audited or patched. Do not build the legacy Pock target expecting Sway's behavior. This alpha is not a claim of complete security, full accessibility coverage or measured performance guarantees.

## Tests

Run model and service tests without changing a VPN connection:

```sh
bash scripts/test-sway.sh
```

After building, these checks require a macOS graphical session:

```sh
bash scripts/test-controls-ui.sh
bash scripts/test-layout-ui.sh
bash scripts/test-integration.sh
```

The integration script currently expects an installed, configured Tailscale client; the normal build does not.

The controls probe uses simulated hardware. Layout probes temporarily present a test bar and windows, including a **100% charging fixture** for spacing checks; they do not change your battery or saved arrangement. Integration checks show native indicators at current levels, exercise a temporary application reopen fixture, and read Tailscale status. They do not connect/disconnect the VPN or deliberately change hardware levels. Test screenshots and executables are written to ignored `build/` output. Reopen Sway afterwards to restore its normal bar.

`Tests/HardwareProbe.swift` is a separate developer diagnostic; its explicit exercise options **do change and restore hardware settings**. It is not part of the default test commands.

Physical tap/swipe behavior, the native banners and Tailscale connect/disconnect have been checked on the verified M1 machine. Sleep/wake edge cases, other machines, accessibility and long-duration CPU/memory measurements still need broader testing.

## Limitations and troubleshooting

- Touch Bar presentation, display/keyboard brightness and native banners rely on isolated **private macOS APIs**. OS updates can change or remove them. Only the local configuration above has been verified.
- Display brightness targets the built-in display; external-monitor DDC control is not implemented.
- Audio devices without writable volume/mute controls may not support adjustments. Per-channel fallback does not preserve a custom stereo balance.
- If a control is unavailable, inspect the latest action in the Sway menu; keyboard ambient-light restrictions can be expected system behavior.
- Running-app icons include apps with no windows. Sway requests their normal reopen behavior, rather than forcing app-specific window creation.
- ChatGPT/Codex allowance is **not implemented or shown**. There is no reserved quota space.
- There is no third-party widget installation, automatic update flow, login-item management or prebuilt release.
- For a bug report, include your Mac model/chip, macOS and Xcode versions, reproduction steps and a Touch Bar screenshot if useful. Remove private information from logs before sharing.

## Source layout

| Path | Purpose |
| --- | --- |
| `Sway/` | Standalone Swift/AppKit app and isolated Objective-C bridges |
| `scripts/` | Build, installation, icon generation and verification commands |
| `Tests/` | Model, service, UI and optional hardware probes |
| `docs/images/` | README screenshot from the running app |
| `docs/IMPLEMENTATION.md` | Italian development log, chronological; later entries supersede earlier ones |
| `docs/specs/` | Original Italian requirements and implementation plans, including future work |
| `Pock/`, `Pock.xcodeproj`, `Podfile` | Inherited upstream source; not used by the Sway build script |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Please report Sway issues in [this fork](https://github.com/nannipy/sway-touchbar/issues), with the tested hardware and OS identified. Changes to private API adapters should include checks for missing symbols and a clear account of what was actually tested.

## Upstream and license

Sway Touch Bar is a fork of [pock/pock](https://github.com/pock/pock), starting from commit [`127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a`](https://github.com/pock/pock/commit/127aac1986e2dc5a3d6995ddbd35e19bf2f0c85a). Upstream history, attribution and the [MIT license](LICENSE.md) are preserved. The [original Pock README](docs/upstream/README.pock.md) is kept for historical reference.

Maintained by [nannipy](https://github.com/nannipy). Sway is an independent personal experiment and is not endorsed by Pock, Apple or Tailscale.
