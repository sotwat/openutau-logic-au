# Logic ProでOpenUtauを使う

このブランチは [OpenUtau Bridge](https://github.com/KakaruHayate/openutau-vst-bridge) にAUv2形式を追加したものです。歌詞・音符の編集と歌声の生成はOpenUtauで行い、Logic Proのソフトウェア音源トラックに音声を送ります。LogicのMIDIノート入力から歌詞や音符を生成する機能はありません。

## このMacでの配置

- DAW連携APIを含むOpenUtau: `~/Applications/OpenUtau DAW Alpha.app`（v0.1.570.9-alpha）。既存の`/Applications/OpenUtau.app`はそのままです。
- AU音源: `~/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component`。
- ローカル中継: `~/Library/Application Support/OpenUtau Bridge/logic_relay.py`。ログイン時に起動するLaunchAgentは`~/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist`です。
- ビルド元: このフォルダ。AU対応と中継のソースは`CMakeLists.txt`、`src/`、`scripts/`にあります。

## Logic Proで使う

1. Logic Proを起動し、ソフトウェア音源トラックを作ります。音源スロットで「AU音源」→「OpenUtau Bridge」→「OpenUtau Bridge」→「ステレオ」を選びます。Logicが起動済みでプラグインが表示されない場合は、プロジェクトを保存してLogicを再起動します。
2. `OpenUtau DAW Alpha.app`でプロジェクトを開き、保存済みであることを確認します。
3. OpenUtauの「ツール」→「DAW Integration...」で「Refresh」を押し、Logic側の`OpenUtau Bridge Relay`を選んで「Connect」を押します。
4. LogicとOpenUtauのテンポを同じ値にし、歌声のレンダリングが終わってからLogicで再生します。音量、パン、エフェクトはLogic側で調整します。
5. OpenUtauの複数トラックを分ける場合は、LogicにAUをトラック数だけ挿し、各インスタンスの「OpenUtau Track」で対象トラックを選びます。Logicプロジェクトを開き直した後は、OpenUtau側で再接続します。

Logic ProはAUを制限された別プロセスで実行するため、AU自身の待受ソケットは作れません。ログイン時に起動するローカル中継が待受と検出ファイルの公開を担当し、AUは中継へ接続します。中継は`127.0.0.1`だけを使用します。連携一覧が空の場合は`launchctl list | grep moe.kakaru.openutau-bridge-relay`で中継の起動を確認し、「Refresh」を押してください。

## 再ビルドと検証

```sh
git submodule update --init --recursive
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target openutau-vst-bridge_auv2 -j 8
sh scripts/install_logic_relay.sh
codesign --force --deep --sign - --timestamp=none 'build/assets/OpenUtau Bridge.component'
ditto 'build/assets/OpenUtau Bridge.component' "$HOME/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component"
auval -v aumu OuBg OuBr
cmake --build build --target bridge-tests -j 8
ctest --test-dir build --output-on-failure
python3 -m unittest discover -s tests -p 'test_logic_relay.py'
```

インストール直後に`auval`がプラグインを見つけられない場合だけ、`killall AudioComponentRegistrar`で登録処理を再起動してから再検証します。

AUv2のビルドには`clap-wrapper`がAppleのAudioUnitSDKを取得します。署名はこのMacでのローカル利用向けです。別のMacへ配布する場合は、そのMacに合った署名と動作検証が必要です。

2026-09-26の確認: `OpenUtauTest.logicx`でAUを挿入し、OpenUtau v0.1.570.9-alphaの保存済み`tell your world.ustx`を接続しました。Logicのテンポを150 BPMに合わせて再生し、音源トラックとStereo Outのレベルメーターに音声信号を確認しました。中継をLaunchAgentに切り替えた後も再接続でき、プロジェクト情報の再受信をログで確認しました。AU検証、C++テスト、ローカル中継のテストも通過しました。
