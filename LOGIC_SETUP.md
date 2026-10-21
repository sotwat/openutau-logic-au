# Logic ProでOpenUtauを使う

このブランチは [OpenUtau Bridge](https://github.com/KakaruHayate/openutau-vst-bridge) にAUv2形式を追加したものです。歌詞・音符の編集と歌声の生成はOpenUtauで行い、Logic Proのソフトウェア音源トラックに音声を送ります。LogicのMIDIノート入力から歌詞や音符を生成する機能はありません。

## このMacでの配置

- OpenUtau: `/Applications/OpenUtau.app`は公式v0.1.576です。`/Applications/OpenUtau AU.app`は同版を元にピアノロールのトラックパッド・ピンチ拡大縮小を追加した改造版です。指を横に広げると時間軸、縦に広げると音程軸を拡大します。タッチ位置が取得できない場合は両軸を拡大します。Logic連携とピンチ操作には後者を使います。共通設定は`Channel=alpha`、旧設定の`Beta=false`です。
- AU音源: `~/Library/Audio/Plug-Ins/Components/OpenUtau Bridge.component`。
- ローカル中継: `~/Library/Application Support/OpenUtau Bridge/openutau-bridge-relay`。ログイン時に起動するLaunchAgentは`~/Library/LaunchAgents/moe.kakaru.openutau-bridge-relay.plist`です。
- ビルド元: このフォルダ。AU対応と中継のソースは`CMakeLists.txt`、`src/`、`scripts/`にあります。

## 別のApple Silicon Macへの導入

[GitHubの公開リリース](https://github.com/sotwat/openutau-logic-au/releases)から最新版の配布ZIP `OpenUtau-Logic-AU-0.1.576-one-click.1-macos-arm64.zip` を取得し、展開して「セットアップ.app」を開きます。ターミナル操作は不要です。AUの登録・検証、中継の起動まで自動で行い、成功を確認できた場合だけ完了を表示します。ピンチ対応OpenUtau AU、AU音源、中継がユーザー領域に入り、既存ファイルはバックアップされます。詳しい条件と署名に関する注意はZIP内の`README.md`を参照してください。Intel Mac向けではありません。

ソースから配布ZIPを作り直すときは、公式OpenUtau `0.1.576`のソースとarm64版アプリを用意し、`scripts/build_openutau_au_pinch.sh`でピンチ対応アプリを生成します。`OPENUTAU_SOURCE`には公式タグのチェックアウト、`OPENUTAU_PINCH_APP`には新規出力先、`DOTNET`には.NET 10 SDKを指定します。検証済みアプリを`/Applications/OpenUtau AU.app`に置き、`sh distribution/build_macos_arm64.sh`を実行します。後者は実行ファイル・`OpenUtau.dll`・`OpenUtau.Core.dll`・ピンチ補助ライブラリのSHA-256を照合してからAUと中継をビルドし、`dist/`にZIPを作ります。声ライブラリや譜面は含めません。

## Logic Proで使う

1. Logic Proを起動し、ソフトウェア音源トラックを作ります。音源スロットで「AU音源」→「OpenUtau Bridge」→「OpenUtau Bridge」→「ステレオ」を選びます。Logicが起動済みでプラグインが表示されない場合は、プロジェクトを保存してLogicを再起動します。
2. `~/Applications/OpenUtau AU.app`でプロジェクトを開き、保存済みであることを確認します。
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

2026-10-04追記: macOSの生のタッチイベントから指の移動を取得する方式へ変更し、ユーザーが横ピンチの時間軸ズームと縦ピンチの音程軸ズームを個別に確認。公式0.1.572.1-alphaへ移植。OpenUtau AUは起動時の自動更新チェックを無効にし、公式版による改造部分の上書きを防ぐ。通常のOpenUtau.appは公式最新版。

## キーボード操作の追加（2026-10-09）

### ノート移動時の確認音（2026-10-20）

「ガイド音を有効化 (Y)」がONのとき、配置済みノートを上下にドラッグすると、移動先の音程のガイド音を鳴らします。音程が変わるたびに切り替え、マウスを離すと停止します。横移動だけでは鳴りません。複数選択や複製ドラッグでは、つかんだノートの実際の音程を使います。ガイド音を鳴らす際は、従来の新規ノート描画と同じくプロジェクト再生を停止します。

再現用パッチは`patches/openutau-note-move-preview-0.1.576.patch`で、`scripts/build_openutau_au_pinch.sh`から適用します。

↑／↓による半音移動、Shift＋↑／↓（Command＋↑／↓も可）によるオクターブ移動でも、移動後の短いガイド音が鳴り、約180msで自動停止します。複数選択では時間順で先頭のノートを試聴します。同時位置の場合は低い方を使います。連打すると新しい音程へ切り替えます。音域外で移動できなかった場合や未選択時には発音しません。

`dotnet run --project OpenUtau.Test -c Debug -- -class '*TransposePreviewTest'`で±1/±12半音の出力波形と周波数、自動停止、ガイドOFF時の無音を検証しています。

ピアノロールで音符を選択し、Shift＋↑で12半音上げ、Shift＋↓で12半音下げます。Command＋Zで取り消せます。音域の上限・下限を超える選択は移動しません。検証用2音（60・64）が上移動で72・76、下移動で60・64、取り消しで72・76になることを実アプリの保存結果で確認しました。

メイン画面で選択したパートはBackspaceでも削除できます。Command＋Zで取り消せます。検証譜面のパート削除後にvoice_partsが空になり、取り消し後に2音ごと復元されることを保存結果で確認しました。

## ノートへ直接入力したひらがなの分配（2026-10-19）

ノートをダブルクリックして「ありがとう」と入力し、Enterで確定すると、そのノートから後ろの既存ノートへ「あ・り・が・と・う」と割り当てます。「きゃ」「きゅ」「きょ」などは1ノートにまとめ、「っ」は独立した1ノートにします。ノートが足りない場合は余った文字を切り捨てます。新しいノートは作りません。Command＋Z一回で分配全体を取り消せます。Tabで確定して次のノートへ移る場合も、分配後の歌詞を表示します。

自動分配の対象はひらがなと長音記号のみの入力です。英語、音素の上書き、VCVエイリアスなどは従来どおり保持します。既存のノートの歌詞は上書きされます。

パッチは`patches/openutau-direct-lyrics-0.1.576.patch`。適用済みの公式ソースで`dotnet run --project OpenUtau.Test -c Debug -- -class '*DirectLyricInputTest'`を実行し、9件合格。既存テストがDebug専用APIを使うためDebug構成を指定します。実アプリでも通常分配・拗音・Tabでの確定・取り消し・残り2ノートへの切り捨てを操作し、保存ファイルの歌詞を照合しました。

## 初回保存時のクラッシュ修正（2026-10-19）

macOSのクラッシュ記録2件で、初回保存ダイアログの表示中にNSRemoteViewのKVO解除が失敗していました。ピンチ補助処理がすべてのウィンドウのcontentViewを動的サブクラスへ変更していたため、対象をAvaloniaのAvnWindow内の正確なAvnViewクラスだけに制限しました。AppKitのビューとKVOが付与したクラスは変更しません。

回帰テストはコンテナ・他のウィンドウ・KVO監視中ビューのクラス保持、保存パネル100回、編集ビューのタッチ受信設定、ピンチ軸判別を検査します。旧コードではクラス保持の検査に失敗し、修正版では合格しました。

```sh
clang -fobjc-arc -fblocks -framework AppKit -arch arm64 tests/test_pinch_window_scope.m -o /tmp/openutau-window-scope-test
/tmp/openutau-window-scope-test
python3 tests/test_macos_distribution.py dist/OpenUtau-Logic-AU-0.1.572.1-alpha-one-click.3-macos-arm64.zip
```

このMacの実アプリで、新規プロジェクトのCommand＋Sによる初回保存6回（ピアノロール起動後の5回を含む）とキャンセル5回を確認し、強制終了は発生しませんでした。配布ZIPの署名、隔離ホームへの導入・再導入、データ保持、改ざん拒否も合格。今回、物理トラックパッドによるピンチ操作とLogicとの再生接続は再検証していません。

2026-10-20追記: メイン画面・ピアノロールでCommand＋Returnを押すと、再生位置をプロジェクトの0秒へ戻します。Return単独では先頭へ戻りません。ピアノロールではReturn（Shift＋Returnも可）で歌詞編集を開き、歌詞・数値の入力中は入力確定として使います。

2026-10-20追記: ピアノロールの音符を選び、「音符のプロパティ」→「歌唱テクニック」でしゃくり・フォール・ハンマリング・オーバーシュート・ヒーカップをONにし、数値とスライダーで調整できます。詳細は[VOCAL_TECHNIQUES.md](VOCAL_TECHNIQUES.md)を参照してください。

## 2026-10-20：公式0.1.576への更新

公式安定版`0.1.576`（ソース`bc194b6fe4897427a73066390b286e11205fd10f`）へ5つの独自パッチを移植しました。公式配布のarm64アプリを土台にし、依存ライブラリも公式最新版へ更新しています。

- 維持：Logic用AUと中継、縦横別ピンチ、Shift＋矢印のオクターブ移動、Backspaceのパート削除、Returnの0秒移動、直接ひらがな分配、5種の調整可能な歌唱テクニック、更新通知の抑止、保存パネルへの干渉修正。
- 旧ベース`0.1.572.1-alpha`以降の公式変更：Expression Graphのズーム・複数選択・コピー/貼り付け、ポルタメントプリセット適用時のピッチ初期化修正、hifisamplerのPフラグの自動ゲイン、DiffSinger音素長モデルと声色マッピングの修正、ピッチ読込範囲、VOICEVOX波形位置、外部wavtoolキャッシュ、DirectMLの安定性、表示の改善など。
- DAW連携・hifisampler本体・トラック試聴用エフェクト・ピッチプリセットは旧ベースにも含まれていました。安定版の更新一覧は`0.1.565`からの累積なので、今回の移植で初めて追加された機能とは区別します。
- 公式DAW連携の参照配布`openutau-vst-bridge 1.0.2`はVST3/CLAP。Logic用AUと中継はこのリポジトリの追加実装です。公式のExpression Graphズームはマウスホイール操作で、ピアノロールの縦横別ピンチとは別機能です。

Releaseビルド成功。歌唱テクニック・直接歌詞入力・公式プリセット・DAW通信の136件と、実C++ブリッジでの通信/音声取得1件が合格。最初の実接続テストはホストの再生ループ指定不足で失敗し、`bridge-host --loop 4`へ修正後に成功。ネイティブ回帰テストの保存パネル100回と軸判別、AUの`auval`、配布ZIPの署名・隔離導入・再導入・データ保持・改ざん拒否も合格。実画面では起動、既存調整値の読込、Shift＋↑のD#4→D#5、Undo、保存、別名保存を確認しました。物理ピンチ、Logicでの楽曲再生、音質、別Mac実機は今回未再検証です。

参照：[公式告知](https://x.com/StAkira/status/2112411669762822246)、[公式安定版](https://github.com/openutau/OpenUtau/releases/tag/0.1.576)、[旧ベースからの差分](https://github.com/openutau/OpenUtau/compare/0.1.572.1-alpha...0.1.576)。

2026-10-21追記: 「歌唱テクニック」にプリングを追加。ONで下降する段差を作り、下げ幅・保持・下降時間を調整できます。USTXへの保存、OFFで元カーブ復元、⌘＋Zに対応します。
