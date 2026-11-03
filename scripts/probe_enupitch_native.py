#!/usr/bin/env python3
"""Run the EnuPitch v0.2.0 model on a synthetic score without playback or a GUI."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    args = parser.parse_args()
    package = args.package.resolve()
    work = args.out.resolve()
    if work.exists():
        raise FileExistsError(f"Use a new output directory: {work}")
    if not (package / "enupitch.py").is_file():
        raise FileNotFoundError(package / "enupitch.py")
    work.mkdir(parents=True)

    # Patch only a private copy; keep the downloaded package intact.
    prepared = work / "package"
    shutil.copytree(package, prepared)
    adjustments = []
    model = prepared / "model/ENUNU_NamineRitsuCC_#4230_5styles_WD_HN-uSFGAN_BEAT"
    for file in [prepared / "extensions/flag_separator_for_enupitch.py",
                 model / "flag_separator/flag_separator_for_enupitch.py"]:
        original = file.read_bytes()
        source = original.decode("utf-8-sig")
        # Python 3.10/3.11 cannot parse PEP 701 expression line breaks.
        normalized = re.sub(r"\r?\n\s*}", "}", source)
        if source != normalized:
            file.write_text(normalized, encoding="utf-8")
            adjustments.append({"path": str(file.relative_to(prepared)),
                                "before_sha256": hashlib.sha256(original).hexdigest(),
                                "change": "Join f-string expression continuation lines"})
    file = model / "timing_auto_correct/enunu_timing_auto_correct.py"
    original = file.read_bytes()
    source = original.decode("utf-8-sig")
    for name in ["settings.txt", "consonant_time.txt"]:
        source = source.replace('current + "\\\\' + name + '"',
                                'os.path.join(current, "' + name + '")')
    file.write_text(source, encoding="utf-8")
    adjustments.append({"path": str(file.relative_to(prepared)),
                        "before_sha256": hashlib.sha256(original).hexdigest(),
                        "change": "Use os.path.join for the two settings paths"})
    (work / "adjustments.json").write_text(json.dumps(adjustments, indent=2))

    sys.path.insert(0, str(prepared))
    import enupitch
    import numpy as np
    import utaupy
    from nnmnkwii.io import hts

    lyrics = ["あ", "い", "う", "え", "お", "あ", "い", "R"]
    pitches = [60, 62, 64, 65, 67, 65, 64, 62]
    fixture = work / "native.tmp"
    score = ("[#VERSION]\nUST Version1.2\n[#SETTING]\nTempo=120\n"
             "VoiceDir=unused\nCacheDir=unused\nProject=synthetic.ust\nMode2=True\n")
    for index, (lyric, pitch) in enumerate(zip(lyrics, pitches)):
        score += (f"[#{index:04d}]\nLength=240\nLyric={lyric}\nNoteNum={pitch}\n"
                  "Velocity=100\nFlags=!0300standard3\n")
    fixture.write_text(score + "[#TRACKEND]\n", encoding="cp932")
    os.chdir(model)
    engine = enupitch.ENUNU(str(model), device="cpu")
    # Use the defaults already in the fixture instead of opening Flet.
    engine.config.extensions.ust_editor = [
        path for path in engine.config.extensions.ust_editor
        if not path.endswith("enupitch_launcher_with_flet.py")
    ]
    engine.set_paths(str(work), "native", str(fixture))
    shutil.copy2(fixture, engine.path_ust)
    shutil.copy2(enupitch.find_table(str(model)), engine.path_table)
    ust = engine.edit_ust(utaupy.ust.load(engine.path_ust))
    ust.write(engine.path_ust)
    enupitch.enulib.utauplugin2score.utauplugin2score(
        engine.path_ust, engine.path_table, engine.path_full_score,
        strict_sinsy_style=False)
    labels = engine.edit_score(hts.load(engine.path_full_score))
    started = time.monotonic()
    engine.svs(labels, dtype=np.float32, vocoder_type="auto", post_filter_type="gv",
               force_fix_vuv=True, segmented_synthesis=False)
    f0 = np.loadtxt(engine.path_f0)
    notes = utaupy.utauplugin.load(str(fixture)).notes
    assert np.isfinite(f0).all() and np.all(f0 > 0)
    assert [note.lyric for note in notes] == lyrics
    assert [note.notenum for note in notes] == pitches
    assert all(note.length == 240 and len(note.pby) > 1 for note in notes)
    assert not list(work.glob("*.wav"))
    result = {"seconds": time.monotonic() - started, "f0_frames": len(f0),
              "finite": True, "min_f0": float(f0.min()), "max_f0": float(f0.max()),
              "notes": [{"lyric": note.lyric, "note": note.notenum,
                         "length": note.length, "points": len(note.pby)} for note in notes]}
    (work / "result.json").write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(json.dumps(result, ensure_ascii=False))


if __name__ == "__main__":
    main()
