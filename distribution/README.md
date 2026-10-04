# OpenUtau・Logic セットアップ（Apple Silicon）

ZIPを展開して「セットアップ.app」を開くと、インストールが始まります。ターミナル操作は不要です。

OpenUtau AU、OpenUtau BridgeのAU音源、中継を配置し、AUの登録・検証と中継の起動まで自動で行います。「セットアップ完了」が表示されたら導入完了です。既存ファイルはユーザーのApplications内のOpenUtau Bridge Backupsに保存します。歌声ライブラリや譜面は含みません。

## Logicで使う

Logicが起動中なら、プロジェクトを保存して再起動してください。ソフトウェア音源トラックの音源スロットで「AU音源 → OpenUtau Bridge → OpenUtau Bridge → ステレオ」を選びます。

OpenUtau AUで保存済みの譜面を開き、「ツール → DAW Integration → Refresh」でOpenUtau Bridge Relayを選んでConnectを押します。LogicとOpenUtauのテンポを合わせてからLogicで再生してください。

## 対応環境と初回の確認

Apple Silicon Mac・Logic Pro向けです。Logic Proは別途必要です。インストール先は現在のユーザーのApplicationsとLibraryです。

この配布にはDeveloper ID署名・公証がありません。macOSが初回起動を止めた場合は、「システム設定 → プライバシーとセキュリティ」でこのセットアップアプリの起動を許可してください。組織の管理ポリシーで許可できない場合もあります。OSの確認を完全に省略するにはDeveloper ID署名・公証が必要です。

ファイルのハッシュと署名を確認してから配置し、配置した3項目のquarantine属性だけを解除します。Gatekeeperの全体設定は変更しません。失敗時は成功表示を出さず、ログを開くボタンを表示します。

## 収録内容とライセンス

OpenUtau 0.1.572.1-alphaにピンチ拡大縮小とLogic向け案内を追加しています。起動時の更新通知は無効です。OpenUtauはMIT（OPENUTAU_LICENSE.txt）、ブリッジと配布コードはMPL-2.0（BRIDGE_LICENSE.txt）です。

ソース：https://github.com/sotwat/openutau-logic-au

別のMacでの実機検証は未実施です。
