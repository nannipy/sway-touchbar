#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Reuse production classes, replacing only the executable's entry point.
python3 - <<'PY'
from pathlib import Path
source = Path('Sway/main.swift').read_text()
a = source.index('let app = NSApplication.shared\nlet delegate = SwayApp()')
b = source.index('// Vector battery:', a)
Path('build/LayoutAppSource.swift').write_text(source[:a] + source[b:])
PY
xcrun swiftc -parse-as-library -module-cache-path build/module-cache -import-objc-header Sway/Bridge.h Sway/Models.swift Sway/Layout.swift Sway/BarView.swift Sway/LayoutSettings.swift Sway/Services.swift Sway/SystemHUD.swift Sway/TailscaleService.swift build/LayoutAppSource.swift Tests/LayoutAppProbe.swift build/KeyboardBridge.o build/HUDBridge.o -framework AppKit -framework CoreAudio -framework IOKit -o build/LayoutAppProbe
build/LayoutAppProbe
