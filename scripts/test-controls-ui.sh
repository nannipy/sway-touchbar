#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
from pathlib import Path
source = Path('Sway/main.swift').read_text()
a = source.index('let app = NSApplication.shared\nlet delegate = SwayApp()')
b = source.index('// Vector battery:', a)
Path('build/ControlAppSource.swift').write_text(source[:a] + source[b:])
PY
xcrun clang -fobjc-arc -c Tests/DirectTouchFixture.m -o build/DirectTouchFixture.o
printf '#import "../Sway/Bridge.h"\n#import "../Tests/DirectTouchFixture.h"\n' > build/ControlTestBridge.h
xcrun swiftc -parse-as-library -module-cache-path build/module-cache -import-objc-header build/ControlTestBridge.h Sway/Models.swift Sway/Layout.swift Sway/BarView.swift Sway/LayoutSettings.swift Sway/Services.swift Sway/SystemHUD.swift Sway/TailscaleService.swift build/ControlAppSource.swift Tests/ControlInteractionProbe.swift build/KeyboardBridge.o build/HUDBridge.o build/DirectTouchFixture.o -framework AppKit -framework CoreAudio -framework IOKit -o build/ControlInteractionProbe
build/ControlInteractionProbe
