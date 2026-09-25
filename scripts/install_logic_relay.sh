#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_relay="$repo/build/openutau-bridge-relay"
agent="$HOME/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist"
installed_dir="$HOME/Library/Application Support/OpenUtau Bridge"
installed_relay="$installed_dir/openutau-bridge-relay"
test -x "$source_relay" || { echo 'Build openutau-bridge-relay first.' >&2; exit 1; }
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs" "$installed_dir"
launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
ditto "$source_relay" "$installed_relay"
codesign --force --sign - --timestamp=none "$installed_relay"
printf '{}' > "$agent"
/usr/libexec/PlistBuddy -c 'Add :Label string moe.kakaru.openutau-bridge-relay' "$agent"
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments array' "$agent"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string $installed_relay" "$agent"
/usr/libexec/PlistBuddy -c 'Add :RunAtLoad bool true' "$agent"
/usr/libexec/PlistBuddy -c 'Add :KeepAlive bool true' "$agent"
/usr/libexec/PlistBuddy -c "Add :StandardOutPath string $HOME/Library/Logs/OpenUtauBridgeRelay.log" "$agent"
/usr/libexec/PlistBuddy -c "Add :StandardErrorPath string $HOME/Library/Logs/OpenUtauBridgeRelay.err.log" "$agent"
launchctl bootstrap "gui/$(id -u)" "$agent"
