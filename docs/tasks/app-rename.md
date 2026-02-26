# アプリ名変更タスク

## ステータス: 未着手

## 背景

App Store審査（2026-02-18）でガイドライン 5.2.5（知的財産・商標違反）によりリジェクトされた。
アプリ名・バンドル名に「iPhone」（Apple商標）が含まれているため、名前の変更が必須。

### リジェクト内容

- ガイドライン: 5.2.5 - Legal - Intellectual Property
- 指摘: アプリ名に「iPhone」を不適切に使用している
- 対象: `昔のiPhoneカメラ` / `OldIPhoneCameraExperience`

---

## 新しいアプリ名

| 項目 | 値 |
|------|-----|
| **日本語名** | あのカメラ |
| **英語名** | AnoCamera |
| **サブタイトル** | みんなが探してる、昔のスマホ画質になるカメラ |

### 由来・意図

「あの頃のカメラ」を極限まで省略。

### メリット

SNS等で「これ『あのカメラ』で撮った」と書かれたとき、見た人が「どのカメラ？」と気になって検索してしまうフック（仕掛け）になる。

### デメリット

日常会話で「あのカメラ起動して」と言った際、文脈によっては通じにくいことがある。

---

## 変更が必要な箇所（TODO）

### 1. ホーム画面の表示名を「あのカメラ」にする

`project.pbxproj` の Debug / Release 両方のビルド設定に以下を追加:

```
INFOPLIST_KEY_CFBundleDisplayName = "あのカメラ";
```

| ファイル | 変更内容 |
|---------|---------|
| `OldIPhoneCameraExperience.xcodeproj/project.pbxproj` | Debug・Release 両セクションに `INFOPLIST_KEY_CFBundleDisplayName = "あのカメラ";` を追加 |

- [ ] pbxproj に Display Name を追加（Debug）
- [ ] pbxproj に Display Name を追加（Release）

### 2. Info.plist の権限説明文から「iPhone 4」を削除

現在の `OldIPhoneCameraExperience/Info.plist`:

| キー | 現在の値 | 変更後 |
|------|---------|--------|
| `NSCameraUsageDescription` | `iPhone 4風の写真を撮影するためにカメラへのアクセスが必要です。` | `レトロな写真を撮影するためにカメラへのアクセスが必要です。` |

- [ ] NSCameraUsageDescription の文言を変更

### 3. App Store Connect（手動）

以下は App Store Connect の管理画面で手動変更する:

- [ ] アプリ名: `あのカメラ`
- [ ] サブタイトル: `みんなが探してる、昔のスマホ画質になるカメラ`

### 4. ドキュメントの更新

- [ ] `docs/appstore-metadata.md` — アプリ名・サブタイトル・説明文・キーワードから「iPhone」表記を修正
- [ ] `CLAUDE.md` — プロジェクト概要のアプリ名を更新
- [ ] その他ドキュメント内の旧アプリ名参照を更新

### 5. バンドルIDの変更（必須）

`PRODUCT_BUNDLE_IDENTIFIER` に「iPhone」が含まれているため、商標違反の再リジェクトリスクがある。

| ファイル | 変更内容 |
|---------|---------|
| `OldIPhoneCameraExperience.xcodeproj/project.pbxproj` | `com.h.dev.oldIPhoneCameraExperience` → `com.h.dev.anoCamera`（Debug・Release・Tests 計4箇所） |
| `OldIPhoneCameraExperience.xcodeproj/project.pbxproj` | `PROVISIONING_PROFILE_SPECIFIER` も連動して更新 |
| `fastlane/.env` | `APP_IDENTIFIER` の値を `com.h.dev.anoCamera` に変更 |
| Apple Developer Console | 新しい App ID `com.h.dev.anoCamera` を登録 |
| fastlane match | 新バンドルIDで証明書・Provisioning Profile を再生成 |

- [x] pbxproj のバンドルID変更（Debug）
- [x] pbxproj のバンドルID変更（Release）
- [x] pbxproj のバンドルID変更（Tests Debug）
- [x] pbxproj のバンドルID変更（Tests Release）
- [x] PROVISIONING_PROFILE_SPECIFIER の更新
- [ ] Apple Developer Console で新 App ID を登録（手動）
- [ ] fastlane match で証明書を再生成（手動）
- [ ] fastlane `.env` の `APP_IDENTIFIER` を更新（手動）

### 6. プロジェクト構造のリネーム（任意・影響大）

以下は変更の影響範囲が大きいため、必須ではない。必要に応じて判断する。

- [ ] Xcodeプロジェクト名（`OldIPhoneCameraExperience.xcodeproj`）
- [ ] ターゲット名・Scheme名
- [ ] フォルダ名（`OldIPhoneCameraExperience/`）
- [ ] GitHub リポジトリ名

### 7. アプリアイコンの差し替え

新しいアイコン画像が用意済み。

| 項目 | 値 |
|------|-----|
| **ソース画像** | `app-icon.png`（プロジェクトルート） |
| **サイズ** | 2048×2048px |
| **配置先** | `OldIPhoneCameraExperience/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| **必要な処理** | 1024×1024pxにリサイズしてから配置（App Store要件） |

#### 手順

1. `app-icon.png`（2048×2048px）を 1024×1024px にリサイズ
2. `OldIPhoneCameraExperience/Assets.xcassets/AppIcon.appiconset/AppIcon.png` を上書き
3. `Contents.json` は変更不要（既に `"size": "1024x1024"` で設定済み）
4. ビルドしてアイコンが正しく表示されることを確認
5. ルートの `app-icon.png`（元画像）はリポジトリに残すかどうかを判断
