"""Apply the EnuPitch v0.2.0 model to an OpenUtau temporary selection."""
import argparse
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys

STYLES = dict(Standard="standard3", Sweet="sweet3", Rock="rock3",
              Breathy="breathy6", Pop="pop3", Growl="growl3")
LOUDNESS = dict(Loudest="3000", Loud="0300", Normal="0030", Soft="0003")
MODEL = "ENUNU_NamineRitsuCC_#4230_5styles_WD_HN-uSFGAN_BEAT"


def prepare(package):
    model = package / "model" / MODEL
    for path in (package / "extensions/flag_separator_for_enupitch.py",
                 model / "flag_separator/flag_separator_for_enupitch.py"):
        source = path.read_text(encoding="utf-8-sig")
        path.write_text(re.sub(r"\n\s*}", "}", source), encoding="utf-8")
    path = model / "timing_auto_correct/enunu_timing_auto_correct.py"
    source = path.read_text(encoding="utf-8-sig")
    for name in ("settings.txt", "consonant_time.txt"):
        source = source.replace('current + "\\\\' + name + '"',
                                'os.path.join(current, "' + name + '")')
    path.write_text(source, encoding="utf-8")
    path = model / "beat_applier/beat_applier.py"
    source = path.read_text(encoding="utf-8-sig")
    source = re.sub(r'(?m)^( +)beat == ("[^"]+"|\'[^\']+\')$', r'\1nonlocal_placeholder = \2', source)
    # The original helper compares instead of assigning and discards the current beat.
    source = source.replace("def measure_length(flag, current_measure):",
                            "def measure_length(flag, current_measure):\n        nonlocal beat")
    source = source.replace("nonlocal_placeholder =", "beat =")
    path.write_text(source, encoding="utf-8")


def generate(args):
    package = args.package.resolve()
    sys.path.insert(0, str(package))
    import enupitch
    import numpy as np
    import utaupy
    from nnmnkwii.io import hts

    source = args.input.resolve()
    output = args.output.resolve()
    work = source.parent
    model = package / "model" / MODEL
    os.chdir(model)
    engine = enupitch.ENUNU(str(model), device="cpu")
    engine.config.extensions.ust_editor = [
        path for path in engine.config.extensions.ust_editor
        if not path.endswith("enupitch_launcher_with_flet.py")]
    feedback = work / "feedback.tmp"
    shutil.copyfile(source, feedback)
    engine.set_paths(str(work), "enu", str(feedback))
    original = utaupy.utauplugin.load(str(source))
    if len(original.notes) < 2:
        raise ValueError("EnuPitch requires at least two notes.")
    prepared = utaupy.ust.load(str(source))
    for i, note in enumerate(prepared.notes):
        note.flags = f"S{args.shift:+d}!{LOUDNESS[args.loudness]}{STYLES[args.style]}"
        note.label = args.meter if i == 0 else ""
    prepared.write(engine.path_ust)
    shutil.copyfile(enupitch.find_table(str(model)), engine.path_table)
    engine.edit_ust(prepared).write(engine.path_ust)
    enupitch.enulib.utauplugin2score.utauplugin2score(
        engine.path_ust, engine.path_table, engine.path_full_score,
        strict_sinsy_style=False)
    labels = engine.edit_score(hts.load(engine.path_full_score))
    engine.svs(labels, dtype=np.float32, vocoder_type="auto", post_filter_type="gv",
               force_fix_vuv=True, segmented_synthesis=False)
    tuned = utaupy.utauplugin.load(str(feedback))
    if len(tuned.notes) != len(original.notes):
        raise ValueError("EnuPitch changed the selection size.")
    result = []
    for before, after in zip(original.notes, tuned.notes):
        if (before.lyric, before.length, before.notenum) != (after.lyric, after.length, after.notenum):
            raise ValueError("EnuPitch changed the selection.")
        if before.lyric.upper() == "R":
            result.append([])
            continue
        x, y = after.pbs
        points = [[x, y]]
        if len(after.pbw) != len(after.pby):
            raise ValueError("Invalid pitch point count.")
        for width, y in zip(after.pbw, after.pby):
            if width < 0 or not math.isfinite(width):
                raise ValueError("Invalid pitch interval.")
            x += width
            if x == points[-1][0]:
                points[-1][1] = y
            else:
                points.append([x, y])
        if len(points) < 2 or not all(math.isfinite(v) for pt in points for v in pt):
            raise ValueError("EnuPitch produced invalid pitch points.")
        result.append(points)
    output.write_text(json.dumps(result, allow_nan=False), encoding="utf-8")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--prepare", action="store_true")
    parser.add_argument("--input", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--meter", choices=("3/4", "4/4", "6/8"), default="4/4")
    parser.add_argument("--shift", type=int, choices=range(-6, 7), default=0)
    parser.add_argument("--style", choices=STYLES, default="Standard")
    parser.add_argument("--loudness", choices=LOUDNESS, default="Loud")
    args = parser.parse_args()
    if args.prepare:
        prepare(args.package)
    else:
        generate(args)


if __name__ == "__main__":
    main()
