#!/bin/sh
set -eu

package=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
payload="$package/payload"
test "$(uname -m)" = arm64 || { echo 'This package requires an Apple Silicon Mac.' >&2; exit 1; }
test -d "$payload/OpenUtau.app" || { echo 'Incomplete package: OpenUtau.app is missing.' >&2; exit 1; }
(
    cd "$package"
    shasum -a 256 -c SHA256SUMS
) || { echo 'Package verification failed; installation stopped.' >&2; exit 1; }

app="$HOME/Applications/OpenUtau.app"
component="$HOME/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component"
relay="$HOME/Library/Application Support/OpenUtau Bridge/openutau-bridge-relay"
agent="$HOME/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist"
prefs="$HOME/Library/OpenUtau/prefs.json"
backup_root="$HOME/Applications/OpenUtau Bridge Backups"
mkdir -p "$HOME/Applications" "$(dirname "$component")" "$(dirname "$relay")" \
    "$(dirname "$agent")" "$(dirname "$prefs")" "$backup_root"
backup=$(mktemp -d "$backup_root/$(date +%Y%m%d-%H%M%S).XXXXXX")

if [ "${OPENUTAU_INSTALL_TEST:-}" != 1 ]; then
    launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
fi

for item in "$app" "$component" "$relay" "$agent"; do
    if [ -e "$item" ]; then
        mv "$item" "$backup/$(basename "$item")"
    fi
done
if [ -e "$prefs" ]; then
    ditto "$prefs" "$backup/prefs.json"
else
    printf '{"Channel":"alpha","Beta":true}\n' > "$prefs"
fi

ditto "$payload/OpenUtau.app" "$app"
ditto "$payload/OpenUtau Bridge.component" "$component"
ditto "$payload/openutau-bridge-relay" "$relay"
xattr -dr com.apple.quarantine "$app" "$component" "$relay" 2>/dev/null || true
if xattr -lr "$app" "$component" "$relay" 2>/dev/null | grep -q com.apple.quarantine; then
    echo 'Could not remove quarantine from the installed files.' >&2
    exit 1
fi
codesign --verify --deep --strict "$component"
codesign --verify --strict "$relay"
plutil -replace Channel -string alpha "$prefs"
plutil -replace Beta -bool YES "$prefs"

printf '{}' > "$agent"
/usr/libexec/PlistBuddy -c 'Add :Label string moe.kakaru.openutau-bridge-relay' "$agent"
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments array' "$agent"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $relay" "$agent"
/usr/libexec/PlistBuddy -c 'Add :RunAtLoad bool true' "$agent"
/usr/libexec/PlistBuddy -c 'Add :KeepAlive bool true' "$agent"
plutil -lint "$agent"

if [ "${OPENUTAU_INSTALL_TEST:-}" != 1 ]; then
    launchctl bootstrap "gui/$(id -u)" "$agent"
    launchctl kickstart -k "gui/$(id -u)/moe.kakaru.openutau-bridge-relay"
fi
echo "Installed OpenUtau, OpenUtau Bridge AU, and relay for $USER."
echo "OpenUtau: $app"
echo "Backup: $backup"
echo 'Open Logic Pro, insert OpenUtau Bridge on a software instrument track, then connect from OpenUtau > Tools > DAW Integration.'
