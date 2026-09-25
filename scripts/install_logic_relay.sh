#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
agent="$HOME/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist"
installed_dir="$HOME/Library/Application Support/OpenUtau Bridge"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs" "$installed_dir"
cp "$script_dir/logic_relay.py" "$installed_dir/logic_relay.py"

/usr/bin/python3 - "$installed_dir/logic_relay.py" "$agent" <<'PY'
import plistlib
import sys
from pathlib import Path

script, agent = sys.argv[1:]
config = {
    "Label": "moe.kakaru.openutau-bridge-relay",
    "ProgramArguments": ["/usr/bin/python3", script],
    "RunAtLoad": True,
    "KeepAlive": True,
    "StandardOutPath": str(Path.home() / "Library/Logs/OpenUtauBridgeRelay.log"),
    "StandardErrorPath": str(Path.home() / "Library/Logs/OpenUtauBridgeRelay.err.log"),
}
with open(agent, "wb") as output:
    plistlib.dump(config, output)
PY

launchctl bootout "gui/$(id -u)" "$agent" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$agent"
