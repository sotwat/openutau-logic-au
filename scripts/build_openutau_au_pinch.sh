#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_dir=${OPENUTAU_SOURCE:?Set OPENUTAU_SOURCE to a checkout of OpenUtau 0.1.576.}
official_app=${OPENUTAU_OFFICIAL_APP:-/Applications/OpenUtau.app}
output_app=${OPENUTAU_PINCH_APP:?Set OPENUTAU_PINCH_APP to a new .app path.}
dotnet=${DOTNET:-dotnet}
patch="$repo/patches/openutau-piano-roll-pinch-0.1.576.patch"

if [[ ! -d "$official_app" && -d "/Applications/OpenUtau AU.app" ]]; then
    official_app="/Applications/OpenUtau AU.app"
fi

test "$(uname -m)" = arm64 || { echo 'Build on Apple Silicon.' >&2; exit 1; }
test "$(git -C "$source_dir" rev-parse HEAD)" = bc194b6fe4897427a73066390b286e11205fd10f || {
    echo 'Expected official OpenUtau 0.1.576 source.' >&2
    exit 1
}
test ! -e "$output_app" || { echo "Output already exists: $output_app" >&2; exit 1; }
official_hash=$(shasum -a 256 "$official_app/Contents/MacOS/OpenUtau.dll" | awk '{print $1}')
test "$official_hash" = fd81ab35c3691715da0feaa8308dd534552df79e1e48ed012a95ea5add644855 || \
test "$official_hash" = d6c8e36f176d62e075d4d70e88607f5611e82220329382567d9fe2ef793324a4 || \
test "$official_hash" = 721d280152da239995f4b5fcee4f734ae7ab31de2c4c358d8d5e3dfcf0c8a147 || {
    echo 'Expected official or current OpenUtau AU 0.1.576 app.' >&2
    exit 1
}

if git -C "$source_dir" apply --check "$patch" 2>/dev/null; then
    git -C "$source_dir" apply "$patch"
elif ! git -C "$source_dir" apply --reverse --check "$patch" 2>/dev/null; then
    echo 'Source differs from the expected patch state.' >&2
    exit 1
fi

guide_patch="$repo/patches/openutau-logic-guide-0.1.576.patch"
if git -C "$source_dir" apply --check "$guide_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$guide_patch"
elif ! git -C "$source_dir" apply --reverse --check "$guide_patch" 2>/dev/null; then
    echo 'Source differs from the expected Logic guide patch state.' >&2
    exit 1
fi

shortcut_patch="$repo/patches/openutau-keyboard-shortcuts-0.1.576.patch"
if git -C "$source_dir" apply --check "$shortcut_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$shortcut_patch"
elif ! git -C "$source_dir" apply --reverse --check "$shortcut_patch" 2>/dev/null; then
    echo 'Source differs from the expected keyboard shortcuts patch state.' >&2
    exit 1
fi

lyrics_patch="$repo/patches/openutau-direct-lyrics-0.1.576.patch"
if git -C "$source_dir" apply --check "$lyrics_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$lyrics_patch"
elif ! git -C "$source_dir" apply --reverse --check "$lyrics_patch" 2>/dev/null; then
    echo 'Source differs from the expected direct lyrics patch state.' >&2
    exit 1
fi

technique_patch="$repo/patches/openutau-vocal-techniques-0.1.576.patch"
if git -C "$source_dir" apply --check "$technique_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$technique_patch"
elif ! git -C "$source_dir" apply --reverse --check "$technique_patch" 2>/dev/null; then
    echo 'Source differs from the expected vocal techniques patch state.' >&2
    exit 1
fi

preview_patch="$repo/patches/openutau-note-move-preview-0.1.576.patch"
if git -C "$source_dir" apply --check "$preview_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$preview_patch"
elif ! git -C "$source_dir" apply --reverse --check "$preview_patch" 2>/dev/null; then
    echo 'Source differs from the expected note move preview patch state.' >&2
    exit 1
fi

gain_patch="$repo/patches/openutau-note-gain-0.1.576.patch"
if git -C "$source_dir" apply --check "$gain_patch" 2>/dev/null; then
    git -C "$source_dir" apply "$gain_patch"
elif ! git -C "$source_dir" apply --reverse --check "$gain_patch" 2>/dev/null; then
    echo 'Source differs from the expected note gain patch state.' >&2
    exit 1
fi

# Keep the bundled XML signature implementation on the fixed NuGet line.
# The official 0.1.576 source resolves 10.0.11, which is affected by the
# current NuGet advisories; apply this reproducible build-time override after
# the feature patches and before restore/build.
core_project="$source_dir/OpenUtau.Core/OpenUtau.Core.csproj"
if grep -q 'System.Security.Cryptography.Xml" Version="10.0.11"' "$core_project"; then
    sed -i '' 's/System.Security.Cryptography.Xml" Version="10.0.11"/System.Security.Cryptography.Xml" Version="10.0.13"/' "$core_project"
elif ! grep -q 'System.Security.Cryptography.Xml" Version="10.0.13"' "$core_project"; then
    echo 'OpenUtau.Core.csproj has an unexpected System.Security.Cryptography.Xml version.' >&2
    exit 1
fi

(
    cd "$source_dir"
    "$dotnet" publish OpenUtau -c Release -r osx-arm64 --self-contained true -m:1 \
        -p:Version=0.1.576 -p:AssemblyVersion=0.1.576 -p:FileVersion=0.1.576 \
        -v:quiet
)

ditto "$official_app" "$output_app"
ditto "$source_dir/OpenUtau/bin/Release/net10.0/osx-arm64/publish/." \
    "$output_app/Contents/MacOS/"
clang -dynamiclib -fobjc-arc -fblocks -framework AppKit -arch arm64 \
    ${OPENUTAU_PINCH_DEBUG:+-DOPENUTAU_PINCH_DEBUG} \
    "$repo/native/openutau_pinch_axis.m" \
    -o "$output_app/Contents/MacOS/libOpenUtauPinchAxis.dylib"
codesign --force --deep --sign - "$output_app"
codesign --verify --deep --strict "$output_app"
echo "Built $output_app"
