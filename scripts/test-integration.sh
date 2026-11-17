#!/bin/bash
# Run in the macOS GUI session. Shows native HUDs and one temporary test window.
# Never connects/disconnects Tailscale or changes volume/brightness levels.
set -euo pipefail
cd "$(dirname "$0")/.."
bash scripts/build-sway.sh
xcrun swiftc -module-cache-path build/module-cache -import-objc-header Sway/Bridge.h Sway/Models.swift Sway/Services.swift Tests/HUDProbe.swift build/KeyboardBridge.o build/HUDBridge.o -o build/HUDProbe
build/HUDProbe
mkdir -p build/ReopenFixture.app/Contents/MacOS
cp Tests/ReopenFixture-Info.plist build/ReopenFixture.app/Contents/Info.plist
xcrun swiftc -module-cache-path build/module-cache Tests/ReopenFixture.swift -o build/ReopenFixture.app/Contents/MacOS/ReopenFixture
codesign --force --sign - build/ReopenFixture.app
xcrun swiftc -parse-as-library -module-cache-path build/module-cache Tests/ReopenProbe.swift -o build/ReopenProbe
build/ReopenProbe
xcrun swiftc -module-cache-path build/module-cache Sway/TailscaleService.swift Tests/TailscaleProbe.swift -o build/TailscaleProbe
build/TailscaleProbe
