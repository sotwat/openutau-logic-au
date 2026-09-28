#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=${OPENUTAU_SOURCE:?Set OPENUTAU_SOURCE to a checkout of OpenUtau 0.1.570.12-alpha.}
official_app=${OPENUTAU_OFFICIAL_APP:-/Applications/OpenUtau.app}
output_app=${OPENUTAU_PINCH_APP:?Set OPENUTAU_PINCH_APP to a new .app path.}
dotnet=${DOTNET:-dotnet}
patch="$repo/patches/openutau-piano-roll-pinch-0.1.570.12-alpha.patch"

test "$(uname -m)" = arm64 || { echo 'Build on Apple Silicon.' >&2; exit 1; }
test "$(git -C "$source_dir" rev-parse HEAD)" = dcae63e0ecca30e4622c2b0838a8987eaca6796e || {
    echo 'Expected official OpenUtau 0.1.570.12-alpha source.' >&2
    exit 1
}
test ! -e "$output_app" || { echo "Output already exists: $output_app" >&2; exit 1; }
test "$(shasum -a 256 "$official_app/Contents/MacOS/OpenUtau.dll" | awk '{print $1}')" = \
    8735a36feed07dc6a0dfc38b1b3d290628442523a4b5f019b952727a99fd0915 || {
    echo 'Expected unmodified official OpenUtau 0.1.570.12-alpha app.' >&2
    exit 1
}

if git -C "$source_dir" apply --check "$patch" 2>/dev/null; then
    git -C "$source_dir" apply "$patch"
elif ! git -C "$source_dir" apply --reverse --check "$patch" 2>/dev/null; then
    echo 'Source differs from the expected patch state.' >&2
    exit 1
fi

(
    cd "$source_dir"
    "$dotnet" build OpenUtau -c Release -r osx-arm64 \
        -p:Version=0.1.570.12 -p:AssemblyVersion=0.1.570.12 -p:FileVersion=0.1.570.12 \
        -v:quiet
)

ditto "$official_app" "$output_app"
ditto "$source_dir/OpenUtau/bin/Release/net10.0/osx-arm64/OpenUtau.dll" \
    "$output_app/Contents/MacOS/OpenUtau.dll"
codesign --force --deep --sign - "$output_app"
codesign --verify --deep --strict "$output_app"
echo "Built $output_app"
