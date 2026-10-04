#!/bin/sh
set -eu

package=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
payload="$package/payload"
install_home=${OPENUTAU_INSTALL_HOME:-$HOME}
if [ "$install_home" != "$HOME" ] && [ "${OPENUTAU_INSTALL_TEST:-}" != 1 ]; then
    echo "An alternate install directory is only supported for tests." >&2
    exit 1
fi
test "$(uname -m)" = arm64 || { echo 'This package requires an Apple Silicon Mac.' >&2; exit 1; }
test -d "$payload/OpenUtau.app" || { echo 'Incomplete package: OpenUtau.app is missing.' >&2; exit 1; }
(
    cd "$package"
    shasum -a 256 -c SHA256SUMS
) || { echo 'Package verification failed; installation stopped.' >&2; exit 1; }

for required in "$payload/OpenUtau Bridge.component" "$payload/openutau-bridge-relay"; do
    test -e "$required" || { echo "配布ファイルが不足しています：$required" >&2; exit 1; }
done
codesign --verify --deep --strict "$payload/OpenUtau.app"
codesign --verify --deep --strict "$payload/OpenUtau Bridge.component"
codesign --verify --strict "$payload/openutau-bridge-relay"

app="$install_home/Applications/OpenUtau AU.app"
component="$install_home/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component"
relay="$install_home/Library/Application Support/OpenUtau Bridge/openutau-bridge-relay"
agent="$install_home/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist"
prefs="$install_home/Library/OpenUtau/prefs.json"
backup_root="$install_home/Applications/OpenUtau Bridge Backups"
mkdir -p "$install_home/Applications" "$(dirname "$component")" "$(dirname "$relay")" \
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
    printf '{"Channel":"alpha","Beta":false}\n' > "$prefs"
fi

ditto "$payload/OpenUtau.app" "$app"
ditto "$payload/OpenUtau Bridge.component" "$component"
ditto "$payload/openutau-bridge-relay" "$relay"
xattr -dr com.apple.quarantine "$app" "$component" "$relay" 2>/dev/null || true
if xattr -lr "$app" "$component" "$relay" 2>/dev/null | grep -q com.apple.quarantine; then
    echo 'Could not remove quarantine from the installed files.' >&2
    exit 1
fi
codesign --verify --deep --strict "$app"
codesign --verify --deep --strict "$component"
codesign --verify --strict "$relay"
plutil -replace Channel -string alpha "$prefs"
plutil -replace Beta -bool NO "$prefs"

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
    relay_started=false
    for attempt in 1 2 3 4 5; do
        if launchctl print "gui/$(id -u)/moe.kakaru.openutau-bridge-relay" 2>/dev/null | grep -q 'state = running'; then
            relay_started=true
            break
        fi
        sleep 1
    done
    if [ "$relay_started" != true ]; then
        echo '中継を起動できませんでした。' >&2
        exit 1
    fi
    /usr/bin/killall AudioComponentRegistrar 2>/dev/null || true
    validation="$install_home/Library/Logs/OpenUtau-AU-Validation.log"
    mkdir -p "$(dirname "$validation")"
    if ! /usr/bin/auval -v aumu OuBg OuBr >"$validation" 2>&1; then
        echo 'AUの登録・検証に失敗しました。配置済みファイルは保持しています。' >&2
        cat "$validation" >&2
        echo "ログ：$validation" >&2
        exit 1
    fi
    if ! grep -q 'AU VALIDATION SUCCEEDED' "$validation"; then
        echo 'AUの検証成功を確認できませんでした。' >&2
        cat "$validation" >&2
        exit 1
    fi
fi
echo "Installed OpenUtau, OpenUtau Bridge AU, and relay for $USER."
echo "OpenUtau: $app"
echo "Backup: $backup"
echo 'Open Logic Pro, insert OpenUtau Bridge on a software instrument track, then connect from OpenUtau > Tools > DAW Integration.'
