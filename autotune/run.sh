#!/bin/sh
set -eu
resources=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mode=$1
data=$2
shift 2
umask 077
mkdir -p "$data"
staging=$(mktemp -d "$data/.prepare.XXXXXX")
trap 'rm -rf "$staging"' EXIT

download() {
    archive=${OPENUTAU_AUTOTUNE_ARCHIVES:+$OPENUTAU_AUTOTUNE_ARCHIVES/${1##*/}}
    if [ -n "$archive" ] && [ -f "$archive" ]; then
        cp "$archive" "$2"
    else
        /usr/bin/curl --fail --silent --show-error --location --retry 2 \
            --proto '=https' --proto-redir '=https' --connect-timeout 20 \
            "$1" -o "$2"
    fi
    actual=$(/usr/bin/shasum -a 256 "$2" | /usr/bin/awk '{print $1}')
    test "$actual" = "$3" || { echo 'Downloaded file checksum mismatch.' >&2; exit 1; }
}

case "$mode" in
    enu)
        runtime="$data/enu-0.2.0-au1"
        if [ ! -f "$runtime/ready" ]; then
            export UV_PYTHON_INSTALL_DIR="$data/python" UV_CACHE_DIR="${UV_CACHE_DIR:-$data/uv-cache}"
            download https://github.com/astral-sh/uv/releases/download/0.13.4/uv-aarch64-apple-darwin.tar.gz \
                "$staging/uv.tar.gz" e0b1d4743ce64c55d9f0f4a444afa6b81125680070ee04e853fcd0f6c1ebf8f1
            /usr/bin/tar -xf "$staging/uv.tar.gz" -C "$staging"
            uv="$staging/uv-aarch64-apple-darwin/uv"
            "$uv" python install 3.10.21
            "$uv" venv --managed-python --python 3.10.21 "$staging/runtime"
            "$uv" pip install --python "$staging/runtime/bin/python" --only-binary :all: \
                --find-links "$resources/wheels" -r "$resources/requirements.txt"
            download https://github.com/oatsu-gh/EnuPitch/releases/download/v0.2.0/EnuPitch-0.2.0.zip \
                "$staging/EnuPitch.zip" e79f424df484b23b77b2e163b6c8fc5aecbfef254809154c7d5e1e124695eb31
            /usr/bin/unzip -q "$staging/EnuPitch.zip" -x '*/python-3.12.7-embed-amd64/*' -d "$staging/runtime"
            "$staging/runtime/bin/python" "$resources/enu.py" "$staging/runtime/EnuPitch-0.2.0" --prepare
            touch "$staging/runtime/ready"
            if [ ! -d "$runtime" ]; then
                mv "$staging/runtime" "$runtime"
            fi
        fi
        export TERM=dumb PYTHONNOUSERSITE=1
        "$runtime/bin/python" -u "$resources/enu.py" "$runtime/EnuPitch-0.2.0" "$@"
        ;;
    apw)
        wine=$1
        input=$2
        if ! /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
            echo 'ROSETTA_REQUIRED' >&2
            exit 78
        fi
        if [ -z "$wine" ]; then
            wine_root="$data/wine-11.21"
            wine="$wine_root/Wine Staging.app/Contents/Resources/wine/bin/wine"
            if [ ! -x "$wine" ]; then
                download https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.21/wine-staging-11.21-osx64.tar.xz \
                    "$staging/wine.tar.xz" d7bcd5abf4df27aae397a7898aef074fea4a2e0b51e0a55aa9659517bbf9d452
                mkdir "$staging/wine"
                /usr/bin/tar -xf "$staging/wine.tar.xz" -C "$staging/wine"
                if [ ! -d "$wine_root" ]; then mv "$staging/wine" "$wine_root"; fi
            fi
        fi
        plugin="$data/AutoPitchwriter-1.7.0/AutoPitchwriter"
        if [ ! -f "$plugin/AutoPitchwriter.exe" ]; then
            download https://canon-voice.com/tools/AutoPitchwriter.zip "$staging/apw.zip" \
                ebfbc7e8633c59e937d6ada58ee96cbac138a57ca96e7e3a4412fdc32156887b
            /usr/bin/unzip -q "$staging/apw.zip" -d "$staging/apw"
            if [ ! -d "$data/AutoPitchwriter-1.7.0" ]; then
                mv "$staging/apw" "$data/AutoPitchwriter-1.7.0"
            fi
        fi
        cd "$plugin"
        export WINEPREFIX="$data/wine-prefix" WINEDLLOVERRIDES='mscoree,mshtml=' LANG=ja_JP.UTF-8 WINEDEBUG=-all
        windows_input="Z:$(printf '%s' "$input" | /usr/bin/tr '/' '\\')"
        "$wine" "$plugin/AutoPitchwriter.exe" "$windows_input"
        ;;
    *) exit 64 ;;
esac
