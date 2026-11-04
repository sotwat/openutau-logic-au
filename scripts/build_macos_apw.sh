#!/bin/bash
set -eu
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
dest=${1:?Pass the AutoTuning resource directory.}
source_dir=${OPENUTAU_OPENHSP_SOURCE:-"$repo/build/autotuning-integration/OpenHSP"}
revision=3dbb8729dad53ee876fc681696c8fe542698860b
if [ ! -d "$source_dir/.git" ]; then
    mkdir -p "$source_dir"
    git -C "$source_dir" init -q
    git -C "$source_dir" fetch --depth 1 https://github.com/onitama/OpenHSP.git "$revision"
    git -C "$source_dir" checkout -q --detach FETCH_HEAD
fi
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
git -C "$source_dir" archive "$revision" LICENSE src/hsp3 | /usr/bin/tar -xf - -C "$work"
h="$work/src/hsp3"
# The original AX and UST use CP932; preserve Windows HSP's byte boundaries.
python3 - "$h/linux/supio_linux.cpp" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
source = path.read_bytes()
source, count = re.subn(rb'if \(a1>=128\) \{[^}]*?if \(\(a1>=252\)&&\(\*p!=0\)\) p\+\+;\s*\}',
    b'if (((a1 >= 129 && a1 <= 159) || (a1 >= 224 && a1 <= 252)) && *p != 0) p++;', source)
if count < 2:
    raise SystemExit("OpenHSP CP932 patch did not apply")
path.write_bytes(source)
PY
/usr/bin/clang++ -O2 -std=c++17 -arch arm64 -DHSPLINUX -DHSP64 -DHSP_COM_UNSUPPORTED \
    -Wno-write-strings -Wno-deprecated-declarations -I "$h" "$repo/autotune/apw.cpp" \
    "$h"/{hsp3,hsp3code,hsp3debug,hsp3int,hspvar_core,hspvar_double,hspvar_int,hspvar_label,hspvar_str,hspvar_struct,stack,strbuf,strnote,dpmread,filepack,hsp3crypt,hsp3utfcnv}.cpp \
    "$h/linux/supio_linux.cpp" -o "$dest/apw-arm64"
/usr/bin/codesign --force --sign - "$dest/apw-arm64"
cp "$work/LICENSE" "$dest/OpenHSP-LICENSE.txt"
