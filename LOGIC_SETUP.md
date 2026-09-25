# Logic ProでOpenUtauを使う

このブランチは [OpenUtau Bridge](https://github.com/KakaruHayate/openutau-vst-bridge) にAUv2形式を追加したものです。歌詞・音符の編集と歌声の生成はOpenUtauで行い、Logic Proのソフトウェア音源トラックに音声を送ります。LogicのMIDIノート入力から歌詞や音符を生成する機能はありません。

## このMacでの配置

- DAW連携APIを含むOpenUtau: `~/Applications/OpenUtau DAW Alpha.app`（v0.1.570.9-alpha）。既存の`/Applications/OpenUtau.app`はそのままです。
- AU音源: `~/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component`。
- ビルド元: このフォルダ。AUのソースは`CMakeLists.txt`の差分です。

## Logic Proで使う

1. Logic Proを起動し、ソフトウェア音源トラックを作ります。音源スロットで「Audio Units」→「OpenUtau Bridge」→「OpenUtau Bridge」を選びます。Logicが起動済みでプラグインが表示されない場合は、プロジェクトを保存してLogicを再起動します。
2. `OpenUtau DAW Alpha.app`でプロジェクトを開き、保存済みであることを確認します。
3. OpenUtauの「ツール」→「DAW Integration...」で、Logic側の`OpenUtau Bridge`を選んで「Connect」を押します。
4. LogicとOpenUtauのテンポを同じ値にし、歌声のレンダリングが終わってからLogicで再生します。音量、パン、エフェクトはLogic側で調整します。
5. OpenUtauの複数トラックを分ける場合は、LogicにAUをトラック数だけ挿し、各インスタンスの「OpenUtau Track」で対象トラックを選びます。Logicプロジェクトを開き直した後は、OpenUtau側で再接続します。

## 再ビルドと検証

```sh
git submodule update --init --recursive
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target openutau-vst-bridge_auv2 -j 8
codesign --force --deep --sign - --timestamp=none 'build/assets/OpenUtau Bridge.component'
ditto 'build/assets/OpenUtau Bridge.component' "$HOME/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component"
auval -v aumu OuBg OuBr
```

インストール直後に`auval`がプラグインを見つけられない場合だけ、`killall AudioComponentRegistrar`で登録処理を再起動してから再検証します。

AUv2のビルドには`clap-wrapper`がAppleのAudioUnitSDKを取得します。署名はこのMacでのローカル利用向けです。別のMacへ配布する場合は、そのMacに合った署名と動作検証が必要です。

2026-09-26の確認: AUのビルド・コード署名・`auval`の検証に成功。AUインスタンスがOpenUtauのDAW連携画面に「Compatible」と表示され、保存済みプロジェクトに接続し、プロジェクト情報を受信しました。Logic Pro内部での挿入・再生は未確認です。
