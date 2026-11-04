#!/bin/sh
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
app=${1:?Pass the OpenUtau AU bundle path.}
python=${OPENUTAU_TUNING_PYTHON:-python3.10}
wheel_dir=${OPENUTAU_TUNING_WHEELS:-"$repo/build/autotuning-wheels"}
mkdir -p "$wheel_dir"
set -- nnmnkwii-0.1.3 pysptk-1.0.1 pyworld-0.3.5 fastdtw-0.3.4 antlr4_python3_runtime-4.9.3
for wheel in "$@"; do
    if ! find "$wheel_dir" -maxdepth 1 -name "$wheel-*.whl" | grep -q .; then
        "$python" -m pip wheel --no-deps --wheel-dir "$wheel_dir" \
            nnmnkwii==0.1.3 pysptk==1.0.1 pyworld==0.3.5 fastdtw==0.3.4 antlr4-python3-runtime==4.9.3
        break
    fi
done
dest="$app/Contents/Resources/AutoTuning"
mkdir -p "$dest/wheels"
cp "$repo/autotune/run.sh" "$repo/autotune/enu.py" "$repo/autotune/requirements.txt" "$dest/"
for wheel in "$@"; do
    found=false
    for f in "$wheel_dir"/"$wheel"-*.whl; do
        case "$f" in
            *cp310*arm64.whl|*none-any.whl) cp "$f" "$dest/wheels/"; found=true ;;
        esac
    done
    "$found" || { echo "Missing arm64 Python 3.10 wheel: $wheel" >&2; exit 1; }
done
