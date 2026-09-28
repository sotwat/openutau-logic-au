# Logic ProでOpenUtauを使う

このブランチは [OpenUtau Bridge](https://github.com/KakaruHayate/openutau-vst-bridge) にAUv2形式を追加したものです。歌詞・音符の編集と歌声の生成はOpenUtauで行い、Logic Proのソフトウェア音源トラックに音声を送ります。LogicのMIDIノート入力から歌詞や音符を生成する機能はありません。

## このMacでの配置

- OpenUtau: `/Applications/OpenUtau.app`は公式v0.1.570.12-alphaです。`/Applications/OpenUtau AU.app`は同版を元にピアノロールのトラックパッド・ピンチ拡大縮小を追加した改造版です。指を横に広げると時間軸、縦に広げると音程軸を拡大します。タッチ位置が取得できない場合は両軸を拡大します。Logic連携とピンチ操作には後者を使います。共通設定は`Channel=alpha`、旧設定の`Beta=false`です。
- AU音源: `~/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component`。
- ローカル中継: `~/Library/Application Support/OpenUtau Bridge/openutau-bridge-relay`。ログイン時に起動するLaunchAgentは`~/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist`です。
- ビルド元: このフォルダ。AU対応と中継のソースは`CMakeLists.txt`、`src/`、`scripts/`にあります。

## 別のApple Silicon Macへの導入

[GitHubの非公開リリース](https://github.com/sotwat/openutau-logic-au/releases)から最新版の配布ZIP `OpenUtau-Logic-AU-0.1.570.12-alpha-pinch-axis.1-macos-arm64.zip` を取得し、展開して`sh install.sh`を実行します。ピンチ対応OpenUtau AU、AU音源、中継がユーザー領域に入り、既存ファイルはバックアップされます。詳しい条件と署名に関する注意はZIP内の`README.md`を参照してください。Intel Mac向けではありません。

ソースから配布ZIPを作り直すときは、公式OpenUtau `0.1.570.12-alpha`のソースとarm64版アプリを用意し、`scripts/build_openutau_au_pinch.sh`でピンチ対応アプリを生成します。`OPENUTAU_SOURCE`には公式タグのチェックアウト、`OPENUTAU_PINCH_APP`には新規出力先、`DOTNET`には.NET 10 SDKを指定します。検証済みアプリを`/Applications/OpenUtau AU.app`に置き、`sh distribution/build_macos_arm64.sh`を実行します。後者は実行ファイルと`OpenUtau.dll`のSHA-256を照合してからAUと中継をビルドし、`dist/`にZIPを作ります。声ライブラリや譜面は含めません。

## Logic Proで使う

1. Logic Proを起動し、ソフトウェア音源トラックを作ります。音源スロットで「AU音源」→「OpenUtau Bridge」→「OpenUtau Bridge」→「ステレオ」を選びます。Logicが起動済みでプラグインが表示されない場合は、プロジェクトを保存してLogicを再起動します。
2. `/Applications/OpenUtau AU.app`でプロジェクトを開き、保存済みであることを確認します。
3. OpenUtauの「ツール」→「DAW Integration...」で「Refresh」を押し、Logic側の`OpenUtau Bridge Relay`を選んで「Connect」を押します。
4. LogicとOpenUtauのテンポを同じ値にし、歌声のレンダリングが終わってからLogicで再生します。音量、パン、エフェクトはLogic側で調整します。
5. OpenUtauの複数トラックを分ける場合は、LogicにAUをトラック数だけ挿し、各インスタンスの「OpenUtau Track」で対象トラックを選びます。Logicプロジェクトを開き直した後は、OpenUtau側で再接続します。

Logic ProはAUを制限された別プロセスで実行するため、AU自身の待受ソケットは作れません。ログイン時に起動するローカル中継が待受と検出ファイルの公開を担当し、AUは中継へ接続します。中継は`127.0.0.1`だけを使用します。連携一覧が空の場合は`launchctl list | grep moe.kakaru.openutau-bridge-relay`で中継の起動を確認し、「Refresh」を押してください。

## 再ビルドと検証

```sh
git submodule update --init --recursive
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target openutau-vst-bridge_auv2 openutau-bridge-relay -j 8
sh scripts/install_logic_relay.sh
codesign --force --deep --sign - --timestamp=none 'build/assets/OpenUtau Bridge.component'
ditto 'build/assets/OpenUtau Bridge.component' "$HOME/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component"
auval -v aumu OuBg OuBr
cmake --build build --target bridge-tests -j 8
ctest --test-dir build --output-on-failure
python3 -m unittest discover -s tests -p 'test_logic_relay.py'
python3 tests/test_native_relay.py build/openutau-bridge-relay
```

インストール直後に`auval`がプラグインを見つけられない場合だけ、`killall AudioComponentRegistrar`で登録処理を再起動してから再検証します。

AUv2のビルドには`clap-wrapper`がAppleのAudioUnitSDKを取得します。配布ZIP内のAUと中継はアドホック署名です。Developer IDによる署名・公証は行っていません。導入スクリプトはハッシュ照合後、配置した3項目だけのquarantine属性を解除します。配布先のmacOSとLogicでの最終確認が必要です。

2026-09-26の確認: `OpenUtauTest.logicx`でAUを挿入し、OpenUtau v0.1.570.9-alphaの保存済み`tell your world.ustx`を接続しました。Logicのテンポを150 BPMに合わせて再生し、音源トラックとStereo Outのレベルメーターに音声信号を確認しました。中継をLaunchAgentに切り替えた後も再接続でき、プロジェクト情報の再受信をログで確認しました。AU検証、C++テスト、ローカル中継のテストも通過しました。

同日追記: `/Applications/OpenUtau.app`も公式v0.1.570.9-alphaに更新しました。公式DMGのSHA-256をGitHub Releasesの値と照合し、両アプリの実行ファイルと`OpenUtau.dll`が一致することを確認しました。通常版は「OpenUtau v0.1.570.9 (alpha)」として起動し、「DAW Integration...」メニューが表示されました。旧アプリと更新前の設定は`~/Applications/OpenUtau Backups/`に保存しました。

配布版追記: Python不要のネイティブ中継に切り替えました。このMacのLogic Pro 12.3.1でAUが中継に接続し、OpenUtauのDAW Integration画面でAPI 1.2 Compatibleから「Connected to 1 plugin(s).」へ移行することを確認しました。別のMacでの実機検証は未実施です。

2026-09-27追記: `/Applications/OpenUtau AU.app`を公式0.1.570.11-alphaへ更新。DMG SHA-256 `9b0e95b7eb1782b2e5401d2731914c869c8b13058bf9a76411cc80fc5f72d864`を公式リリースの値と照合。起動画面の版表示と「DAW Integration...」メニューを確認し、起動時に更新通知は表示されなかった。ブリッジAUの`auval`、C++テスト、リレーのテストは合格。新しい版とLogic Proとの実接続は未確認。配布ZIPのSHA-256は`04691266721570203bdb879cff93c163dee4ea881699f451b1c2dd32fd0f5d86`。

2026-09-28追記: 更新通知の再発を確認。共通設定に旧`Beta=true`が残ると起動時に`Channel=alpha`が`beta`へ上書きされることがOpenUtau公式ソースで判明。両アプリを公式0.1.570.12-alphaへ更新し、`Beta=false`、`Channel=alpha`へ修正。通常版を起動して更新通知が出ないことを確認。配布インストーラも旧`Beta`を無効に変更した。

同日追記: 旧OpenUtauアプリ本体7つをゴミ箱へ移動。`/Applications`、`~/Applications`、Downloads、Desktop、Documentsで残るOpenUtauアプリは上記2つのみ。音源、譜面、設定、配布ZIPは変更していません。
