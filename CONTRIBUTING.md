# Contributing to Sway Touch Bar

Sway is an experimental personal fork of Pock. Please open Sway issues and pull requests in [nannipy/sway-touchbar](https://github.com/nannipy/sway-touchbar), rather than the upstream Pock tracker.

## Before changing code

Read the [README](README.md) for the current features, build instructions, tested hardware and private API limitations. The original Italian plans in `docs/specs/` include future requirements; their presence does not mean a feature is implemented. `docs/IMPLEMENTATION.md` is a chronological log, with later entries superseding older ones.

The current target lives in `Sway/` and builds with `scripts/build-sway.sh`. The legacy Pock project is retained for history and attribution; its dependencies are not part of the standalone Sway build.

## Development

1. Fork this repository and create a branch from `main`.
2. Build with `bash scripts/build-sway.sh`.
3. Run `bash scripts/test-sway.sh`.
4. For UI changes, run the relevant graphical probes documented in the README and test on a physical Touch Bar where possible. Report simulated input separately from device testing.
5. Update both README languages when changing user-facing setup or behavior.
6. Open a pull request explaining the problem, the resulting behavior, and the hardware/macOS configuration used for verification.

Keep changes focused. Preserve the centered layout, native gestures, local preferences, menu-bar-only application behavior and upstream attribution. Do not add remote telemetry, unreviewed widget execution, bundled credentials, or administrator requirements for normal operation.

Private macOS APIs must remain isolated, check symbol availability and fail safely. Never describe a deployment target or successful compilation as proof of device compatibility.

## Reporting a bug

Include reproduction steps, expected/actual behavior, Mac model/chip, macOS and Xcode versions, and whether the issue affects taps, direct-touch swipes or both. A Touch Bar screenshot can help; press Shift–Command–6 on a supported Mac. Strip private data from logs and screenshots.

For a security issue involving private data or credentials, avoid putting those details in a public issue. Use GitHub's private vulnerability reporting if enabled, or request a private reporting channel without disclosing the sensitive material.

Contributions are provided under the repository's [MIT license](LICENSE.md).
