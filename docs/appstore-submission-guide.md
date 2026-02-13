# App Store 提出手順書

このドキュメントは、OldIPhoneCameraExperience アプリをApp Storeに提出するための手順をまとめたものです。

## 前提条件

- [ ] Apple Developer Program に登録済み（年間 $99）
- [ ] 実機テストが完了している（`docs/device-testing-guide.md` 参照）
- [ ] すべてのテストケースが通過している
- [ ] Xcode 15.0 以降がインストールされている
- [ ] fastlane がインストールされている

## 手順

### 1. App Store Connect でアプリを作成

1. [App Store Connect](https://appstoreconnect.apple.com/) にログイン
2. 「マイApp」→「＋」→「新規App」をクリック
3. 以下の情報を入力:
   - **プラットフォーム:** iOS
   - **名前:** OldIPhone Camera
   - **主言語:** 日本語
   - **バンドルID:** `com.yourname.OldIPhoneCameraExperience`（Xcodeで設定したもの）
   - **SKU:** `oldiPhonecamera-001`（一意の識別子）
   - **ユーザーアクセス:** フルアクセス

### 2. アプリ情報を入力

#### 2.1 基本情報

- **カテゴリ:** 写真/ビデオ
- **サブカテゴリ:** なし
- **価格:** 無料

#### 2.2 説明文

`docs/appstore-metadata.md` の内容を参照して、以下を入力:

- **プロモーションテキスト** (170文字以内)
- **説明** (4000文字以内)
- **キーワード** (100文字以内)
- **サポートURL:** `https://github.com/KakizakiHayate/OldIPhoneCameraExperience`
- **マーケティングURL:** （任意）

#### 2.3 スクリーンショット

以下のサイズのスクリーンショットを用意:

**必須:**
- **6.7インチ（iPhone 15 Pro Max）:** 1290 x 2796 px（5枚）
- **6.5インチ（iPhone 14 Plus）:** 1284 x 2778 px（5枚）

**推奨構成:**
1. カメラプレビュー画面（メイン画面）
2. 撮影した写真の例（暖色系フィルター適用）
3. フラッシュオン時の画面
4. 前面カメラ使用時の画面
5. 撮影アニメーション（虹彩絞り）

**撮影方法:**

実機で以下の操作を行い、スクリーンショットを撮影:

```bash
# シミュレータでスクリーンショット撮影
# Cmd + S でスクリーンショット保存
```

実機の場合:
- iPhone 15 Pro Max: サイドボタン + 音量上ボタン
- スクリーンショットは「写真」アプリに保存される

#### 2.4 アプリプレビュー動画（任意）

30秒以内の動画を作成:

1. カメラ起動
2. プレビュー表示
3. シャッターボタンタップ
4. 虹彩絞りアニメーション
5. 写真保存完了

### 3. App審査情報を入力

#### 3.1 連絡先情報

- **名前:** （あなたの名前）
- **電話番号:** （あなたの電話番号）
- **メールアドレス:** （あなたのメールアドレス）

#### 3.2 審査メモ

以下の内容を記載:

```
このアプリは、iPhone 4の撮影体験を再現するレトロカメラアプリです。

【テスト手順】
1. アプリを起動すると、カメラ権限のダイアログが表示されます。「許可」をタップしてください。
2. カメラプレビューが表示されます。
3. 画面下部中央のシャッターボタンをタップすると、写真が撮影されます。
4. 撮影時に虹彩絞りアニメーションが表示されます。
5. フォトライブラリ権限のダイアログが表示されます（初回のみ）。「許可」をタップしてください。
6. 写真がカメラロールに保存されます。
7. 「写真」アプリで撮影した写真を確認できます。

【特徴】
- 暖色系フィルター（iPhone 4風の色味）
- 画角クロップ（中央80%）
- 手ブレシミュレーション（ジャイロスコープデータを使用）
- スキューモーフィズムUI（iOS 4〜6風のデザイン）

【権限】
- カメラ: 写真撮影に使用
- フォトライブラリ: 撮影した写真の保存に使用
- モーション: 手ブレシミュレーションに使用
```

#### 3.3 デモアカウント

不要（ログイン機能なし）

### 4. 年齢制限を設定

- **年齢制限:** 4+（すべての年齢対象）
- **コンテンツの説明:** なし

### 5. プライバシー情報を入力

#### 5.1 データ収集

「いいえ、このAppからユーザーデータを収集しません」を選択

#### 5.2 プライバシーポリシー

`docs/appstore-metadata.md` の「プライバシーポリシー」セクションを参照して、以下のURLを入力:

- **プライバシーポリシーURL:** `https://github.com/KakizakiHayate/OldIPhoneCameraExperience/blob/main/PRIVACY.md`

（事前に `PRIVACY.md` をリポジトリに追加しておく必要があります）

### 6. ビルドをアップロード

#### 6.1 Xcodeでアーカイブ

1. Xcodeでプロジェクトを開く
2. メニューバーから `Product` → `Archive` を選択
3. アーカイブが完了したら、Organizerウィンドウが開く
4. 「Distribute App」をクリック
5. 「App Store Connect」を選択
6. 「Upload」を選択
7. 署名オプションを確認して「Next」
8. アップロード完了を待つ

#### 6.2 fastlaneでアップロード（推奨）

```bash
cd OldIPhoneCameraExperience

# ビルド番号を自動インクリメント
fastlane run increment_build_number

# App Store Connect にアップロード
fastlane release
```

`Fastfile` の内容:

```ruby
default_platform(:ios)

platform :ios do
  desc "Release to App Store"
  lane :release do
    # ビルド
    build_app(
      scheme: "OldIPhoneCameraExperience",
      export_method: "app-store"
    )
    
    # App Store Connect にアップロード
    upload_to_app_store(
      skip_metadata: true,
      skip_screenshots: true,
      submit_for_review: false
    )
  end
end
```

### 7. TestFlightでテスト（任意）

1. App Store Connect で「TestFlight」タブを開く
2. アップロードしたビルドが「処理中」→「テスト準備完了」になるまで待つ（10〜30分）
3. 「内部テスト」または「外部テスト」でテスターを追加
4. テスターに配布してフィードバックを収集

### 8. 審査に提出

1. App Store Connect で「App Store」タブを開く
2. 「バージョン情報」セクションで、アップロードしたビルドを選択
3. すべての必須項目が入力されていることを確認
4. 「審査に提出」をクリック

### 9. 審査結果を待つ

- 審査には通常 **1〜3日** かかります
- 審査中は App Store Connect で進捗を確認できます
- 審査が完了すると、メールで通知が届きます

### 10. リリース

審査が承認されたら:

1. App Store Connect で「リリース」をクリック
2. アプリがApp Storeで公開されます

## トラブルシューティング

### 審査リジェクト

**理由:** 2.1 - Performance: App Completeness

**解決策:** アプリがクラッシュしていないか、すべての機能が動作しているか確認してください。

---

**理由:** 4.0 - Design

**解決策:** スクリーンショットがガイドラインに準拠しているか確認してください。

---

**理由:** 5.1.1 - Legal: Privacy - Data Collection and Storage

**解決策:** プライバシーポリシーが正しく設定されているか確認してください。

### ビルドアップロードエラー

**エラー:** `Invalid Bundle. The bundle contains disallowed file 'Frameworks'.`

**解決策:** Xcodeの `Build Settings` で `EMBEDDED_CONTENT_CONTAINS_SWIFT` を `YES` に設定してください。

---

**エラー:** `Missing required icon file.`

**解決策:** `Assets.xcassets` にすべてのサイズのアイコンが追加されているか確認してください。

## チェックリスト

提出前に以下を確認:

- [ ] すべてのテストケースが通過している
- [ ] 実機でアプリが正常に動作する
- [ ] スクリーンショットが用意されている（6.7インチ、6.5インチ）
- [ ] 説明文、キーワードが入力されている
- [ ] プライバシーポリシーが設定されている
- [ ] 審査メモが記載されている
- [ ] ビルドがApp Store Connect にアップロードされている
- [ ] バージョン番号が正しい（例: 1.0.0）
- [ ] ビルド番号が正しい（例: 1）

## 参考リンク

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect ヘルプ](https://help.apple.com/app-store-connect/)
- [fastlane ドキュメント](https://docs.fastlane.tools/)
