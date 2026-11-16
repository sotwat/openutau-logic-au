# UtauV Auto Pitch

Source: [emeraldsingers/UtauV 0.0.1.6](https://github.com/emeraldsingers/UtauV/tree/0.0.1.6), commit `dd35b832977abe025c76c3bda02eb16171fc542b`. The MIT notice is preserved in [LICENSE.txt](LICENSE.txt) and installed as `Contents/Resources/AutoTuning/licenses/UtauV-LICENSE.txt`.

The port adapts `OpenUtau.Core/Editing/AutoPitchEdit.cs` to return a curve without mutating notes. The host commits only selected PITD intervals in one undo operation. The AP toolbar action follows UtauV's existing control.

The model is downloaded on first use, not redistributed in this repository or app. The publisher's registry labels version 1.2 as stable; 1.3 is a test release. Version 1.2 is pinned here:

- URL: https://github.com/emeraldsingers/UtauV_Packages/releases/download/curve_v_1.3/autopitchcurve.oudep
- SHA-256: `dff9515c84b199cd18570d6395f800719faf2efc65248fcea93541d394a15ba2`
- Archive size: 4,841,483 bytes
- Install ID/version: `autopitchcurve` / `1.2`
- Contents: `oudep.yaml`, `autopitch.onnx`, `autopitch.onnx.config.json`, `autopitch.onnx.vocab.json`

The release tag includes `1.3`, but this archive's metadata declares **1.2**. Code licensing and model redistribution permission are separate; the archive contained no model license at inspection on 2026-11-16.
