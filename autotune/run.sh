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
        export OMP_NUM_THREADS=2 VECLIB_MAXIMUM_THREADS=2 OPENBLAS_NUM_THREADS=2
        "$runtime/bin/python" -u "$resources/enu.py" "$runtime/EnuPitch-0.2.0" "$@"
        ;;
    apw)
        # A process started before the bundle update still passes an unused Wine path.
        if [ "$#" -eq 2 ]; then shift; fi
        input=$1
        plugin="$data/AutoPitchwriter-1.7.0/AutoPitchwriter"
        if [ ! -f "$plugin/AutoPitchwriter.exe" ]; then
            download https://canon-voice.com/tools/AutoPitchwriter.zip "$staging/apw.zip" \
                ebfbc7e8633c59e937d6ada58ee96cbac138a57ca96e7e3a4412fdc32156887b
            /usr/bin/unzip -q "$staging/apw.zip" -d "$staging/apw"
            if [ ! -d "$data/AutoPitchwriter-1.7.0" ]; then
                mv "$staging/apw" "$data/AutoPitchwriter-1.7.0"
            fi
        fi
        exe="$plugin/AutoPitchwriter.exe"
        actual=$(/usr/bin/shasum -a 256 "$exe" | /usr/bin/awk '{print $1}')
        test "$actual" = 151c32d478811097b98a0238546ea84669cf4e1f750df8ef1445dd631d4fb189
        cp "$plugin/pitch.ust" "$plugin/AutoPitchwriter" "$staging/"
        LC_ALL=C /usr/bin/awk '{sub(/\r$/, ""); printf "%s\r\n", $0}' "$input" > "$staging/selection.tmp"
        (
            cd "$staging"
            "$resources/apw-arm64" "$exe"
            LC_ALL=C /usr/bin/grep -q '^\[#INSERT\]' selection.tmp
        )
        cp "$staging/selection.tmp" "$input"
        ;;
    *) exit 64 ;;
esac
