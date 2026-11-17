#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/module-cache
xcrun swiftc -module-cache-path build/module-cache Sway/Models.swift Tests/AdjustmentTests.swift -o build/AdjustmentTests
build/AdjustmentTests
xcrun swiftc -module-cache-path build/module-cache Sway/TailscaleService.swift Tests/TailscaleTests.swift -o build/TailscaleTests
build/TailscaleTests
xcrun swiftc -module-cache-path build/module-cache Sway/Layout.swift Tests/LayoutTests.swift -o build/LayoutTests
build/LayoutTests
