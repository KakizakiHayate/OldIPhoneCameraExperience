# OldIPhone Camera Experience

iPhone 4の撮影体験を最新iPhoneで完全再現するレトロカメラアプリ

## 概要

**OldIPhone Camera** は、iPhone 4の撮影体験そのものを最新iPhoneで完全再現するレトロカメラアプリです。単なるフィルターアプリではなく、古いiPhoneのハードウェア制限が生む「本物の不完全さ」まで含めて再現します。

### 特徴

- **暖色系の独特な色味**: iPhone 4特有のオレンジ〜黄色がかった暖色系フィルター
- **画角の狭さ**: 中央80%にクロップし、古いiPhoneの画角を再現
- **手ブレシミュレーション**: ジャイロスコープデータを使った本物の手ブレ効果
- **スキューモーフィズムUI**: iOS 4〜6時代の立体的なUIデザイン
- **虹彩絞りアニメーション**: 撮影時のレトロなシャッター演出

## スクリーンショット

（実機テスト後に追加予定）

## 技術スタック

- **言語**: Swift 5.9
- **フレームワーク**: SwiftUI, AVFoundation, CoreImage, CoreMotion
- **アーキテクチャ**: MVVM + Protocol-Oriented Programming
- **テスト**: XCTest (TDD)
- **CI/CD**: GitHub Actions, fastlane

## 開発環境

- Xcode 15.0 以降
- iOS 17.0 以降
- Swift 5.9 以降

## セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/KakizakiHayate/OldIPhoneCameraExperience.git
cd OldIPhoneCameraExperience

# Xcodeでプロジェクトを開く
open OldIPhoneCameraExperience.xcodeproj
```

## ビルド & 実行

### Xcodeから実行

1. Xcodeでプロジェクトを開く
2. 実機またはシミュレータを選択
3. `Cmd + R` でビルド & 実行

### Makefileから実行

```bash
# ビルド
make build

# テスト実行
make test

# Lint実行
make lint

# クリーン
make clean
```

## テスト

```bash
# すべてのテストを実行
make test

# 特定のテストを実行
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## ドキュメント

- [MVP要件](docs/mvp-requirements.md) - MVP機能要件
- [実装ガイド](docs/implementation-guide.md) - 実装手順とテストケース
- [アーキテクチャ](docs/architecture.md) - アーキテクチャ設計
- [データモデル](docs/data-model.md) - データモデル定義
- [テストケース](docs/test-cases.md) - 全テストケース一覧
- [実機テストガイド](docs/device-testing-guide.md) - 実機テスト手順
- [App Store提出ガイド](docs/appstore-submission-guide.md) - App Store提出手順
- [App Storeメタデータ](docs/appstore-metadata.md) - App Store提出用メタデータ

## プロジェクト構成

```
OldIPhoneCameraExperience/
├── OldIPhoneCameraExperience/          # メインアプリ
│   ├── Core/                           # コア機能
│   │   └── Constants/                  # 定数定義
│   ├── Models/                         # データモデル
│   ├── Services/                       # ビジネスロジック
│   ├── ViewModels/                     # ViewModel層
│   └── Views/                          # UI層
│       ├── Components/                 # UIコンポーネント
│       └── CameraScreen.swift          # メイン画面
├── OldIPhoneCameraExperienceTests/     # テストコード
├── docs/                               # ドキュメント
├── fastlane/                           # CI/CD設定
└── Makefile                            # ビルドスクリプト
```

## 開発フロー

### ブランチ戦略

- `main`: 本番環境（App Store公開版）
- `develop`: 開発環境
- `feature/*`: 機能開発ブランチ

### コミットメッセージ

```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
test: テスト追加
refactor: リファクタリング
chore: その他の変更
```

### プルリクエスト

1. `feature/*` ブランチで開発
2. テストを書く（TDD）
3. `make lint` でコードスタイルをチェック
4. `make test` でテストを実行
5. PRを作成し、`develop` にマージ

## ライセンス

MIT License

## 作者

Kakizaki Hayate ([@KakizakiHayate](https://github.com/KakizakiHayate))

## 謝辞

このプロジェクトは、Z世代を中心に流行している「古いiPhone実機での撮影」の障壁を解消し、より多くの人がレトロな撮影体験を楽しめるようにすることを目的としています。

## プライバシーポリシー

[PRIVACY.md](PRIVACY.md) を参照してください。

## サポート

バグ報告や機能リクエストは、[GitHub Issues](https://github.com/KakizakiHayate/OldIPhoneCameraExperience/issues) で受け付けています。
