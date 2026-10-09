#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${OPENUTAU_APP:-/Applications/OpenUtau AU.app}
version=0.1.572.1-alpha-one-click.2
expected_app_sha=ef7d7e0d65b57cc5ec9a6ec2f06c0c363d6a185739069565056d51fba636d97c
expected_dll_sha=f92022ce6487be27f3caeddf3f14db0c32afc80e2122827f1e52ddda966ad9c7
expected_axis_sha=a97502004a60d0fa377ae1eda9641b9724d002b62f1b56691e3e9e8da4016451
name="OpenUtau-Logic-AU-${version}-macos-arm64"

test -d "$app" || { echo "OpenUtau app not found: $app" >&2; exit 1; }
actual_app_sha=$(shasum -a 256 "$app/Contents/MacOS/OpenUtau" | awk '{print $1}')
test "$actual_app_sha" = "$expected_app_sha" || {
    echo "Expected the verified OpenUtau AU $version (arm64); found a different executable." >&2
    exit 1
}
actual_dll_sha=$(shasum -a 256 "$app/Contents/MacOS/OpenUtau.dll" | awk '{print $1}')
test "$actual_dll_sha" = "$expected_dll_sha" || {
    echo "Expected the verified OpenUtau AU $version (arm64); found a different OpenUtau.dll." >&2
    exit 1
}
actual_axis_sha=$(shasum -a 256 "$app/Contents/MacOS/libOpenUtauPinchAxis.dylib" | awk '{print $1}')
test "$actual_axis_sha" = "$expected_axis_sha" || { echo "Pinch-axis helper hash mismatch." >&2; exit 1; }
test "$(uname -m)" = arm64 || { echo 'Build on Apple Silicon.' >&2; exit 1; }

cmake -S "$repo" -B "$repo/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$repo/build" --target openutau-vst-bridge_auv2 openutau-bridge-relay -j 8
test "$(lipo -archs "$repo/build/assets/OpenUtau Bridge.component/Contents/MacOS/OpenUtau Bridge")" = arm64
test "$(lipo -archs "$repo/build/openutau-bridge-relay")" = arm64

mkdir -p "$repo/dist"
staging_root=$(mktemp -d "$repo/dist/.stage.XXXXXX")
trap 'rm -rf "$staging_root"' EXIT
stage="$staging_root/$name"
setup="$stage/セットアップ.app"
resources="$setup/Contents/Resources"
mkdir -p "$resources/payload" "$setup/Contents/MacOS"
cat > "$setup/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>moe.kakaru.openutau-logic-setup</string>
<key>CFBundleName</key><string>OpenUtau Logic Setup</string>
<key>CFBundleDisplayName</key><string>セットアップ</string>
<key>CFBundleExecutable</key><string>Setup</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
clang -fobjc-arc -fblocks -arch arm64 -mmacosx-version-min=11.0 -framework Cocoa \
    "$repo/distribution/setup_macos.m" -o "$setup/Contents/MacOS/Setup"
ditto "$app" "$resources/payload/OpenUtau.app"
ditto "$repo/build/assets/OpenUtau Bridge.component" "$resources/payload/OpenUtau Bridge.component"
ditto "$repo/build/openutau-bridge-relay" "$resources/payload/openutau-bridge-relay"
codesign --force --deep --sign - --timestamp=none "$resources/payload/OpenUtau Bridge.component"
codesign --force --sign - --timestamp=none "$resources/payload/openutau-bridge-relay"
codesign --verify --deep --strict "$resources/payload/OpenUtau Bridge.component"
codesign --verify --strict "$resources/payload/openutau-bridge-relay"

ditto "$repo/distribution/install_macos_arm64.sh" "$resources/install.sh"
ditto "$repo/distribution/OPENUTAU_LICENSE.txt" "$stage/OPENUTAU_LICENSE.txt"
ditto "$repo/LICENSE" "$stage/BRIDGE_LICENSE.txt"
ditto "$repo/distribution/README.md" "$stage/README.md"
(
    cd "$resources"
    shasum -a 256 'payload/OpenUtau.app/Contents/MacOS/OpenUtau' \
        'payload/OpenUtau.app/Contents/MacOS/OpenUtau.dll' \
        'payload/OpenUtau.app/Contents/MacOS/libOpenUtauPinchAxis.dylib' \
        'payload/OpenUtau Bridge.component/Contents/MacOS/OpenUtau Bridge' \
        'payload/openutau-bridge-relay' > SHA256SUMS
)
codesign --force --sign - --timestamp=none "$setup"
codesign --verify --deep --strict "$setup"
(cd "$stage" && shasum -a 256 "セットアップ.app/Contents/MacOS/Setup" > SETUP-SHA256.txt)
ditto -c -k --sequesterRsrc --keepParent "$stage" "$repo/dist/$name.zip"
shasum -a 256 "$repo/dist/$name.zip"
