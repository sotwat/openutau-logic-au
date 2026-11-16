# COEIROINK音源で歌わせる

開発版のOpenUtau AUは、ONNXへ変換したCOEIROINK v2／MYCOEIROINKのVITS音源を読み込めます。UtauV 0.0.1.6のMIT実装を移植しました。公開ZIPのone-click.8には未収録です。

## 音源の準備

音源フォルダに、次のファイルが必要です。

```text
音源フォルダ/
  metas.json
  model/
    スタイルID/
      config.yaml
      duration.onnx
      synth.onnx
```

通常のCOEIROINK音源に入っている `.pth` は、そのままでは読み込めません。[作者のONNX変換ツール](https://github.com/emeraldsingers/coeiroink-onnx-exporter)で変換してください。変換元を保持し、別の作業フォルダで行います。ツールのREADMEにPython環境と必要パッケージの導入手順があります。変換にはPython／PyTorchを使いますが、変換後の歌唱合成はOpenUtau AU内のARM64版ONNX Runtimeで行います。

```sh
python export.py "/path/to/voicebank"
```

複数の `.pth` が同じスタイルフォルダにある場合、作者のツールは名前順の最初のファイルを選びます。意図した重みと同時点のconfigだけを作業フォルダへ用意してください。モデルや音声の使用・改変・配布には、各音源の規約が適用されます。変換ツールや第三者の音源本体は、OpenUtau AUへ同梱していません。

## OpenUtau AUで使う

1. 変換済みの音源フォルダを `~/Library/OpenUtau/Singers/` に置き、OpenUtau AUを再起動します。character.txt／character.yamlがなければ音源検索時に作成します。
2. トラック左側の音源名からCOEIROINK音源を選びます。音素変換は「COEIROINK JA」、レンダラーは「COEIROINK」を選びます。JA+は子音と母音の境界を分けて編集する方式です。
3. ノートへひらがな・カタカナの歌詞を入力します。音符の音高・長さへ合わせて歌声を生成します。スタイルはCLR（voice color）で選べ、変更位置で合成区間を分けます。

歌唱合成には、Packagesから導入する `pc_nsf_hifigan_44.1k_hop512_128bin_2025.02` ボコーダーも必要です。未導入の場合は、不足パッケージの案内に従って導入してください。別のボコーダーでは、44.1 kHz／hop 512という条件も確認が必要です。

ノート音量・6種の歌唱テクニック・ビブラート・PITDを既存の合成経路から反映します。レンダラーはノートを作り直さず、設定はUSTXへ保存されます。COEIROINK本体で設定した話速・声高・プリセットを読み込む機能ではありません。アプリ本体の起動やサーバー接続は不要です。

## 移植と確認

移植元は[UtauV 0.0.1.6](https://github.com/emeraldsingers/UtauV/tree/0.0.1.6/OpenUtau.Core/Coeiroink)（`dd35b832977abe025c76c3bda02eb16171fc542b`）。既存14パッチの後に `patches/openutau-coeiroink-0.1.576.patch` を適用します。ライセンス通知は `third_party/utauv/LICENSE.txt` とアプリ内の `AutoTuning/licenses/UtauV-LICENSE.txt` に保持します。

Mac上での変換確認には、作者のexporter `5c8775225669caf10260fa01f176bf931fbd2637`（export.py SHA-256 `976a8a1208e705da60c3d6d6223dedc180264a9a054e98afa619f88f35b0697a`）を使用しました。このツールは取得元から実行し、リポジトリには再配布していません。

2026-11-16〜17、花園トキネ131epochを変換し、短い歌詞で合成を確認しました。ONNXとPyTorchの比較では最大絶対誤差約0.000003。音程を解析し、ノート音量50%で波形が半分になること、歌唱テクニック設定が生成後も保持されることを試験しています。音を鳴らす検査は行っていません。他の音源の音質・互換性は未検証です。

実モデル試験は `COEIROINK_TEST_BANK` に変換済み音源フォルダを指定し、OpenUtau.Testの `OpenUtau.Core.Coeiroink.CoeiroinkRendererTest` を実行します。任意の `COEIROINK_TEST_PROJECT` で画面確認用USTXを保存できます。指定がない場合は実モデル試験を失敗にし、未検証を合格扱いにしません。
