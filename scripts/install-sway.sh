#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
target="${1:-/Applications/Sway.app}"
if [[ "${target##*/}" != "Sway.app" ]]; then
    echo "La destinazione deve terminare con Sway.app" >&2
    exit 1
fi
if [[ -e "$target" ]]; then
    identifier=$(/usr/bin/plutil -extract CFBundleIdentifier raw "$target/Contents/Info.plist" 2>/dev/null || true)
    if [[ "$identifier" != "dev.sway.touchbar" ]]; then
        echo "La destinazione contiene un’altra applicazione; non è stata modificata." >&2
        exit 1
    fi
fi
bash scripts/build-sway.sh
if /usr/bin/pgrep -x Sway >/dev/null; then
    echo "Chiudi Sway prima di installare o aggiornare l’app." >&2
    exit 1
fi
parent="$(dirname "$target")"
mkdir -p "$parent"
staging=$(mktemp -d "$parent/.Sway-install.XXXXXX")
cleanup() {
    if [[ -e "$staging/Previous.app" && ! -e "$target" ]]; then
        mv "$staging/Previous.app" "$target"
    fi
    rm -rf "$staging"
}
trap cleanup EXIT
/usr/bin/ditto build/Sway.app "$staging/Sway.app"
/usr/bin/codesign --verify --deep --strict "$staging/Sway.app"
if [[ -e "$target" ]]; then mv "$target" "$staging/Previous.app"; fi
mv "$staging/Sway.app" "$target"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target"
echo "Sway installata in $target"
