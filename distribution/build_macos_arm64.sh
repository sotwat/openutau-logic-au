#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${OPENUTAU_APP:-/Applications/OpenUtau AU.app}
version=0.1.576-one-click.7
expected_app_sha=f079541f8216cbd240837bd3d204b041cc8e3498fc568be2fa3f89fc029f9a4e
expected_release_app_sha=b7c5540024a9f83043d66e09b54957b15e20d5f65160061cfc8a079813d6e7dc
expected_dll_sha=e44e2c12cf4686668a06153d4d191397a935b1598fed50bda9161aadb6d42e6c
expected_core_sha=43a6d5d8409c264f6b2e9a5ee88c693451f8420e4f84420bc8a3e7debc53af07
expected_axis_sha=4fda6e2e0cce594017a9d6cc0cd8a7ce8d973ffe6bb306d0003692999af6ac8b
name="OpenUtau-Logic-AU-${version}-macos-arm64"

test -d "$app" || { echo "OpenUtau app not found: $app" >&2; exit 1; }
actual_app_sha=$(shasum -a 256 "$app/Contents/MacOS/OpenUtau" | awk '{print $1}')
test "$actual_app_sha" = "$expected_app_sha" ||
test "$actual_app_sha" = "$expected_release_app_sha" || {
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
python3 "$repo/scripts/configure_macos_documents.py" "$resources/payload/OpenUtau.app"
codesign --force --deep --sign - --timestamp=none "$resources/payload/OpenUtau.app"
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
        'payload/OpenUtau.app/Contents/MacOS/openutau-register-files' \
        'payload/OpenUtau.app/Contents/Info.plist' \
        'payload/OpenUtau Bridge.component/Contents/MacOS/OpenUtau Bridge' \
        'payload/openutau-bridge-relay' > SHA256SUMS
)
codesign --force --sign - --timestamp=none "$setup"
codesign --verify --deep --strict "$setup"
(cd "$stage" && shasum -a 256 "セットアップ.app/Contents/MacOS/Setup" > SETUP-SHA256.txt)
ditto -c -k --sequesterRsrc --keepParent "$stage" "$repo/dist/$name.zip"
shasum -a 256 "$repo/dist/$name.zip"
