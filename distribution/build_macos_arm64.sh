#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${OPENUTAU_APP:-/Applications/OpenUtau AU.app}
version=0.1.572.1-alpha-one-click.7
expected_app_sha=3e88322c1547a989959c3e93dca59d66e8d52ec99d061744194dbb2ae94981da
expected_dll_sha=7d2e706ca67b2c0866214d07e8588bab4f4cd756e1a2b4d718c4b66823e0e06b
expected_core_sha=166569bf397be0c0731ab3409d8698c777189a274c69f1c88be18c1e2182e0ff
expected_axis_sha=6a74557d75563a5e26e6b9a9eb5f81dcab1062dfe345906a133942659c78e4db
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
actual_core_sha=$(shasum -a 256 "$app/Contents/MacOS/OpenUtau.Core.dll" | awk '{print $1}')
test "$actual_core_sha" = "$expected_core_sha" || { echo "Vocal-technique core hash mismatch." >&2; exit 1; }
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
        'payload/OpenUtau.app/Contents/MacOS/OpenUtau.Core.dll' \
        'payload/OpenUtau.app/Contents/MacOS/libOpenUtauPinchAxis.dylib' \
        'payload/OpenUtau Bridge.component/Contents/MacOS/OpenUtau Bridge' \
        'payload/openutau-bridge-relay' > SHA256SUMS
)
codesign --force --sign - --timestamp=none "$setup"
codesign --verify --deep --strict "$setup"
(cd "$stage" && shasum -a 256 "セットアップ.app/Contents/MacOS/Setup" > SETUP-SHA256.txt)
ditto -c -k --sequesterRsrc --keepParent "$stage" "$repo/dist/$name.zip"
shasum -a 256 "$repo/dist/$name.zip"
