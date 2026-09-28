#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${OPENUTAU_APP:-/Applications/OpenUtau AU.app}
version=0.1.570.12-alpha-pinch-axis.1
expected_app_sha=88404d8e87458a58188e4052158a920fd9911242df9c8a9e57278c5fa499f8cb
expected_dll_sha=9038628dcd139b724f33119c14a6d5bdc509c8c26baf12292f9105c3bee97d13
expected_axis_sha=d303f353d8286b368fbc30e69f5cae4fe2e652faee04c80043484a34233230bc
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
mkdir -p "$stage/payload"
ditto "$app" "$stage/payload/OpenUtau.app"
ditto "$repo/build/assets/OpenUtau Bridge.component" "$stage/payload/OpenUtau Bridge.component"
ditto "$repo/build/openutau-bridge-relay" "$stage/payload/openutau-bridge-relay"
codesign --force --deep --sign - --timestamp=none "$stage/payload/OpenUtau Bridge.component"
codesign --force --sign - --timestamp=none "$stage/payload/openutau-bridge-relay"
codesign --verify --deep --strict "$stage/payload/OpenUtau Bridge.component"
codesign --verify --strict "$stage/payload/openutau-bridge-relay"

ditto "$repo/distribution/install_macos_arm64.sh" "$stage/install.sh"
ditto "$repo/distribution/OPENUTAU_LICENSE.txt" "$stage/OPENUTAU_LICENSE.txt"
ditto "$repo/LICENSE" "$stage/BRIDGE_LICENSE.txt"
ditto "$repo/distribution/README.md" "$stage/README.md"
(
    cd "$stage"
    shasum -a 256 'payload/OpenUtau.app/Contents/MacOS/OpenUtau' \
        'payload/OpenUtau.app/Contents/MacOS/OpenUtau.dll' \
        'payload/OpenUtau.app/Contents/MacOS/libOpenUtauPinchAxis.dylib' \
        'payload/OpenUtau Bridge.component/Contents/MacOS/OpenUtau Bridge' \
        'payload/openutau-bridge-relay' > SHA256SUMS
)
ditto -c -k --sequesterRsrc --keepParent "$stage" "$repo/dist/$name.zip"
shasum -a 256 "$repo/dist/$name.zip"
