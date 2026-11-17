#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/Sway.app/Contents/MacOS build/Sway.app/Contents/Resources build/module-cache
if [[ ! -f build/Sway.app/Contents/Resources/Sway.icns || scripts/make-sway-icon.swift -nt build/Sway.app/Contents/Resources/Sway.icns ]]; then
    xcrun swiftc -module-cache-path build/module-cache scripts/make-sway-icon.swift -o build/MakeSwayIcon
    build/MakeSwayIcon build/Sway.iconset
    iconutil -c icns build/Sway.iconset -o build/Sway.app/Contents/Resources/Sway.icns
fi
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 -c Sway/KeyboardBridge.m -o build/KeyboardBridge.o
xcrun clang -fobjc-arc -mmacosx-version-min=13.0 -c Sway/HUDBridge.m -o build/HUDBridge.o
xcrun swiftc -target "$(uname -m)-apple-macos13.0" -O -module-cache-path build/module-cache -import-objc-header Sway/Bridge.h Sway/Models.swift Sway/Layout.swift Sway/BarView.swift Sway/LayoutSettings.swift Sway/Services.swift Sway/SystemHUD.swift Sway/TailscaleService.swift Sway/main.swift build/KeyboardBridge.o build/HUDBridge.o -framework AppKit -framework CoreAudio -framework IOKit -o build/Sway.app/Contents/MacOS/Sway
cp Sway/Info.plist build/Sway.app/Contents/Info.plist
codesign --force --sign - build/Sway.app
