# OpenUtau AU — Logic Pro・Apple Silicon版

[最新版のセットアップZIPをダウンロード](https://github.com/sotwat/openutau-logic-au/releases/latest)

ZIPを展開して「セットアップ.app」を開くと、OpenUtau AUとLogic用AUを導入できます。現在の配布は **0.1.576-one-click.8** です。Logicでの使い方は[LOGIC_SETUP.md](LOGIC_SETUP.md)、初回起動や導入条件は[同梱README](distribution/README.md)を参照してください。

歌声ライブラリ・譜面・Logic Proは含みません。AutoPitchwriterとEnuPitchの本体・モデル・実行環境は初回に配布元から取得するため、インターネット接続が必要です。Developer ID署名・公証はありません。

## 公式配布版に追加した機能

2026年11月5日に、公式の安定版[0.1.576](https://github.com/openutau/OpenUtau/releases/tag/0.1.576)と、最新試験版[0.1.577.8 Alpha](https://github.com/openutau/OpenUtau/releases/tag/0.1.577.8-alpha)のソースを照合した一覧です。この配布のベースは安定版0.1.576です。Alpha固有の新機能をすべて取り込んだ版ではありません。

- **Logic Pro用Audio Unit音源**：OpenUtau Bridge AUとApple Silicon用のローカル中継を追加。公式DAW連携のVST3/CLAPに加え、Logic Proから利用できます。譜面編集は別のOpenUtauウィンドウで行います。
- **Logic用の接続案内**：DAW Integration画面にAUの導入状態とLogic向けの接続先・手順を表示します。
- **セットアップ.app**：OpenUtau AU・AU音源・中継の配置、AU登録・検証、中継の自動起動設定をまとめて行います。ターミナルでのインストール操作は不要です。
- **ピアノロールの縦横別ピンチ**：二本指の横方向の動きで時間軸、縦方向の動きで音程軸を拡大・縮小。移動方向から軸を判定し、ジェスチャー中は固定します。判定待ちではズームせず、タッチ情報を取得できないときは時間軸だけを動かします。
- **トラック画面の横ピンチ**：配置エリアと時間目盛りで、ポインタ位置の時刻を基準に時間軸を拡大・縮小。トラックの高さは変えず、縦ピンチは無視します。
- **Shift＋上下矢印でオクターブ移調**：公式の既存ショートカットに加え、Shiftでも選択ノートを12半音上下できます。
- **Backspaceでパート削除**：トラック画面で選択したリージョン（パート）をMacのdelete／Backspaceキーで削除できます。
- **Command＋Returnで先頭へ移動**：トラック画面とピアノロールで再生位置を0秒に戻します。再生中は先頭から再生を続けます。
- **ひらがな歌詞の直接分配**：ノートに「ありがとう」などを入力すると後続ノートへ分配。「きゃ」などは1ノートにまとめ、ノートが足りなければ余りを切り捨てます。
- **6種の歌唱テクニック**：しゃくり・フォール・ハンマリング・プリング・オーバーシュート・ヒーカップをノート単位でON/OFFでき、深さ・長さなどを数値調整できます。通常のノート間ピッチカーブを編集する方式です。
- **歌唱テクニックの保存と復元**：USTXにON/OFFと調整値を保存。再生・接続点補正や生成点の手調整後も設定を維持し、OFFでそのテクニックの効果を取り除きます。
- **配置済みノートのドラッグ確認音**：ノートを上下に動かすとその高さの確認音が鳴り、指を離すと止まります。
- **矢印キー移調時の確認音**：上下移動やオクターブ移調の結果を短い確認音で聞けます。既存のガイド音スイッチに従います。
- **ノート音量（0〜200%）**：「音符のプロパティ → 基本」でノートごとの音量を調整し、USTXに保存。DiffSingerでも使用できます。
- **べた打ちUST書き出し**：音符と歌詞を残し、調声を外したUSTを別ファイルへ出力します。元のUSTXは変更しません。
- **Finderの譜面連携**：UST・USTX・MIDIを「このアプリケーションで開く」から読み込み、UST・USTXはセットアップ時に既定のアプリへ登録。MIDIと音声の既定アプリは変更しません。
- **AutoPitchwriterの標準メニュー**：作者配布1.7.0をApple Silicon上のOpenHSPで動かす呼び出し機能を追加。Rosetta・Wineは不要です。ノート再作成で独自の音量・歌唱テクニック設定が失われることを実行前に表示し、Undoに対応します。対応区間は4/4です。
- **AutoPitchwriterの45候補エディター**：候補に動きを表す名前を付け、各点の時間と音程を数値で調整できます。全45候補・159点で、候補単位の初期化に対応します。
- **AutoPitchwriterのグラフ編集**：カーブの点を左右・上下へドラッグして時間・音程を調整でき、数値欄と双方向に連動します。編集する候補を選べますが、譜面への候補割り当ては元の自動判定です。
- **EnuPitchの標準メニュー**：v0.2.0のモデルをARM64版Pythonで実行。強弱・6種の歌唱スタイル・−6〜＋6半音のスタイルシフトをAUの画面から指定できます。
- **EnuPitchの選択・拍子処理**：元GUIのスタイルシフト未反映と拍子処理を修正。3/4・4/4・6/8と小節途中の選択に対応します。拍子・テンポの変更箇所は区間を分けます。
- **EnuPitchの設定保持と進捗表示**：ピッチだけを元ノートへ書き戻し、歌詞・音高・長さ・ノート音量・歌唱テクニック設定を保持。進捗表示、キャンセル、30分の処理上限、Undoに対応します。
- **EnuPitchの点数削減**：生成時に「元の点を残す・控えめ・標準・強め」を選べます。カーブの形を比較し、5・10・20セントを目安に余分な点を間引きます。
- **生成済みピッチの点数削減**：選択ノートまたはパート全体を、再推論せずに間引けます。ノート音量・歌唱テクニック設定を保持し、Undoに対応します。
- **公式アップデーターによる上書きの抑止**：改造版を公式アプリへ置き換えないよう、起動時の公式更新案内を停止しています。

鍵盤の確認音、一般的なDAWプロジェクト同期・再生位置同期、通常のUST/MIDI入出力、ビブラート、音声のドラッグ＆ドロップなど、公式にもある機能は独自追加として数えていません。各エンジンの制約や操作手順は[AUTOTUNING.md](AUTOTUNING.md)と[LOGIC_SETUP.md](LOGIC_SETUP.md)を参照してください。

## ブリッジの元プロジェクト

以下はVST3/CLAP版を含む上流ブリッジの説明です。

[![CI](https://github.com/KakaruHayate/openutau-vst-bridge/actions/workflows/ci.yml/badge.svg)](https://github.com/KakaruHayate/openutau-vst-bridge/actions/workflows/ci.yml) [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/KakaruHayate/openutau-vst-bridge) ![Format: VST3 | CLAP](https://img.shields.io/badge/Format-VST3%20%7C%20CLAP-blue)  [![License](https://img.shields.io/github/license/KakaruHayate/openutau-vst-bridge?style=flat&color=blue)](https://github.com/KakaruHayate/openutau-vst-bridge/blob/main/LICENSE)

[![Bridge Target](https://img.shields.io/badge/Target-OpenUtau-green?style=flat)]() [![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Linux-informational)]() 

A thin plugin that puts OpenUtau's rendered audio on the DAW timeline. Editing stays in
the OpenUtau window; the plugin holds the connection, the audio, and the placement.

This is the plugin half of OpenUtau's DAW integration. The other half is the API under
`OpenUtau.Core/DawIntegration/` in the main repository. [`PROTOCOL.md`](PROTOCOL.md) is
the contract between them and is a verbatim copy of the file that ships there — **change
one and you must change the other.**

## What it does

- **Project sync (v1.0).** Receives the USTX baseline and every debounced update, pulls
  part audio by hash over the data plane, and places each part on the DAW timeline at its
  absolute position — converted to the host's sample rate on arrival.
- **Multi-instance, multi-track (v1.0).** One plugin instance per DAW track; a stepped
  "OpenUtau Track" parameter chooses which track the instance answers for. All instances
  share one OpenUtau connection per instance; each advertises itself through its own
  discovery file.
- **Pre-fader output (v1.0).** OpenUtau's volume/pan/mute fields stay on the wire but are
  not applied: the DAW owns gain, pan, mute and solo, with a constant √0.5 trim so the
  level matches OpenUtau's own centred-track playback.
- **Bounce-friendly offline rendering (v1.0).** An offline (non-realtime) render waits
  for missing part audio instead of printing holes; real-time playback never waits.
- **Info window (v1.1).** A small window showing project name, saved state, connection
  state, tempo, transport and the track list with this instance's track marked. Windows
  for now; other platforms simply advertise no gui.
- **Playhead sync (v1.1).** The DAW's transport position is sent one-way to OpenUtau —
  immediately on state changes, every 100 ms while playing, and on scrubs of more than
  50 ms while parked. OpenUtau's own playhead follows the DAW, never the reverse.
- **Tempo guard (v1.1).** The DAW's tempo is reported when it changes; OpenUtau warns
  once per distinct mismatch that bars will misalign (there is no tempo-map sync).

## Formats

Built clap-first: one implementation, wrapped into each format by
[clap-wrapper](https://github.com/free-audio/clap-wrapper).

| Format | Reaches |
| --- | --- |
| CLAP | Bitwig, Reaper, FL Studio, Studio One, Qtractor |
| VST3 | Ableton Live, Cubase/Nuendo, and the rest |

Pro Tools is out of scope: AAX requires an SDK available only under an Avid agreement.

## Documentation

- English: [User Manual](MANUAL.md) · [Release Notes](RELEASE.md) · this README ·
  [`PROTOCOL.md`](PROTOCOL.md) for the wire contract.
- 中文：[使用说明书](MANUAL.zh-CN.md) · [发布说明](RELEASE.zh-CN.md)

## Licensing

This project is MPL-2.0. MPL-2.0 is file-level copyleft, so the permissively licensed
dependencies below keep their own terms and notices while everything under `src/` stays
MPL-2.0.

| Dependency | License | Pinned as |
| --- | --- | --- |
| [clap](https://github.com/free-audio/clap) | MIT | submodule, `1.2.10` |
| [clap-wrapper](https://github.com/free-audio/clap-wrapper) | MIT | submodule, `v0.16.0` |
| [VST3 SDK](https://github.com/steinbergmedia/vst3sdk) | MIT | fetched by clap-wrapper, `v3.8.0_build_66` |
| [r8brain-free-src](https://github.com/avaneev/r8brain-free-src) | MIT | submodule, `version-6.5` |
| [xxHash](https://github.com/Cyan4973/xxHash) | BSD-2-Clause | submodule, `v0.8.3` |
| [nlohmann/json](https://github.com/nlohmann/json) | MIT | vendored header, `libs/json/VERSION.txt` |

Three things worth knowing:

- **The VST3 SDK became MIT in 3.8.0.** GPLv3 and the Steinberg proprietary agreement are
  no longer offered, so shipping a permissively licensed VST3 needs no dispensation. This
  is why no clean-room VST3 implementation is used here.
- Only xxHash's *library* is BSD-2-Clause; the `xxhsum` command-line tool is GPLv2. This
  build uses the library alone.
- "VST" is still a Steinberg **trademark**, which is separate from the MIT code. It
  constrains use of the name and logo in branding, not redistribution of the binary.

JUCE was considered and rejected: it is AGPLv3 or commercial, and neither can ship inside
an MPL-2.0 project.

## Building

Needs CMake 3.28+ and a C++20 compiler. On Windows that means MSVC; MinGW is untested.

```sh
git clone --recurse-submodules https://github.com/KakaruHayate/openutau-vst-bridge.git
cd openutau-vst-bridge
cmake -B build
cmake --build build --config Release --target openutau-vst-bridge_all
```

Artifacts land in `build/assets/`. The first configure clones the VST3 SDK, so it needs
network access.

On Windows, `bridge-install` copies both formats into the per-user plug-in folders under
`%LOCALAPPDATA%\Programs\Common`, which every host scans and which needs no administrator
rights:

```sh
cmake --build build --config Release --target bridge-install
```

The VST3 is built as a bundle folder (`OpenUtau Bridge.vst3/Contents/x86_64-win/`) rather than a
bare DLL. Both load in most hosts, but only the folder is what the current VST3 spec describes.

## Layout

```
src/
  bridge_entry.*    the three symbols a format module needs, and the exported clap_entry
  plugin.cpp        descriptor, factory, parameters, state, gui hookup, and the CLAP process callback
  gui.h gui_win32.cpp the info window: CLAP gui extension and its Win32 backend
  transport.h       where a block sits on the host's timeline
  session.*         the worker thread that owns the connection and publishes snapshots
  socket.* stream.h the listener and the byte streams over it
  reader.* frame.*  lines and data-plane frames off a stream
  messages.*        control-plane JSON, both directions
  connection.*      requests, responses, notifications, heartbeat
  discovery.*       the advertisement file OpenUtau scans for
  audio_store.*     hash to PCM, converted to the host's sample rate
  timeline.*        the snapshot the audio thread mixes, and the handover to it
  fader.h hash.*    OpenUtau's volume and pan law; XXH64 and its wire form
tools/
  bridge_host.cpp   runs a session outside a DAW, for checking against OpenUtau itself
libs/               dependencies, all permissively licensed
PROTOCOL.md         the wire contract, mirrored from the main repository
```

`src/` builds into a static library that knows nothing about formats;
`make_clapfirst_plugins` links it into one module per format.

## Testing

```sh
cmake --build build --config Release --target bridge-tests
./build/tests/Release/bridge-tests
```

The tests link that static library directly and open real loopback sockets, so the protocol is
exercised end to end — discovery file, framing, store, snapshot and mixer — without loading a
module into a host.

### Checking against OpenUtau itself

The suite here speaks to a fake OpenUtau and OpenUtau's own suite speaks to a fake plugin, which
leaves one thing neither can catch: the two disagreeing. `bridge-host` closes that by running the
real session outside a DAW.

```sh
cmake -B build -DBRIDGE_BUILD_HOST=ON
cmake --build build --config Release --target bridge-host
./build/Release/bridge-host --dir /tmp/bridge-live --rate 44100 --loop 4
```

Then, in the main repository, point the opt-in integration test at the same directory — it is
skipped when the variable is unset, so it costs an ordinary run nothing:

```sh
OPENUTAU_BRIDGE_DISCOVERY='C:\Users\you\AppData\Local\Temp\bridge-live' \
    dotnet test OpenUtau.Test/OpenUtau.Test.csproj --filter DawRealPluginTest
```

That drives the shipping `DawManager` — real discovery scan, real USTX serializer, real audio
extraction — against this plugin, and the whole flow is visible in `bridge-host`'s output:

```
info: OpenUtau connected on port 50512.
info: Project baseline received, 754 bytes.      <- init
t=  1s  peak L 0.25  R 0.25                  <- updatePartLayout, getAudio, mixed
t=  3s  peak L 0.0000  R 0.0000
info: Project baseline received, 754 bytes.      <- playbackStarted, flushed back as updateUstx
```

The level is worth checking rather than glancing at: the bridge sends the rendered OpenUtau part at
unity, and the DAW owns track gain, pan, mute and solo. A constant 0.25 part therefore reads 0.25
in each channel before the DAW mixer. This is deliberate: changing an OpenUtau editor fader must
not change the input level seen by a compressor or other DAW effect while the final mix is being
tuned. At a host rate other than 44100 expect a few percent more at the part's edges — that is the
resampler's overshoot on a rectangular window, not a gain error.

Without `--loop`, the transport never restarts, so `playbackStarted` is never sent and that half of
the flow goes unverified.

### Steinberg's validator

CI runs this on all three platforms on every push, so what follows is only needed to reproduce a
failure locally. clap-wrapper's own `vst3_validator` target shells out to a nested Ninja build, so
where Ninja is absent it is easier to configure the SDK directly:

```sh
cmake -S build/cpm/vst3sdk -B build/validator-vs -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DSMTG_ADD_VSTGUI=OFF -DSMTG_ENABLE_VSTGUI_SUPPORT=OFF \
      -DSMTG_ENABLE_VST3_PLUGIN_EXAMPLES=OFF -DSMTG_ENABLE_VST3_HOSTING_EXAMPLES=OFF
cmake --build build/validator-vs --config Release --target validator
./build/validator-vs/bin/Release/validator.exe "build/assets/VST3/OpenUtau Bridge.vst3"
```

It instantiates the plugin through the factory and drives initialize, setActive, state and process
for real, including a run of `process` on another thread — which is as close to a host as anything
that is not one. Expect 47 passed, 0 failed.
