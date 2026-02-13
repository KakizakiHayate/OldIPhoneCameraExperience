# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**レトロiPhoneカメラアプリ — iPhone 4の撮影体験を完全再現**

### コンセプト
最新iPhoneを手に取った瞬間、iPhone 4に戻ったかのような完全なレトロ撮影体験を提供するカメラアプリ。UIも写真もiPhone 4そのものを再現する。

### MVPで検証する仮説
「最新iPhoneユーザーは、UIから写真まで丸ごとiPhone 4を再現したカメラアプリに撮影体験としての価値を感じるか」

### ターゲットユーザー
- Z世代（10代後半〜20代半ば）
- SNS（Instagram、TikTok）に写真を投稿する習慣があるユーザー
- 「エモい」写真やレトロな雰囲気を好むユーザー

---

## 技術仕様

### 対象プラットフォーム
- iOS限定（iPhone 12以降、iOS 16以上）

### 技術スタック

| 要素 | 技術 |
|------|------|
| 言語 | Swift |
| UI | SwiftUI + カスタムスキューモーフィズムコンポーネント |
| デザイン | iOS 4〜6風カスタムUI（グラデーション、テクスチャ、シャドウ） |
| カメラ制御 | AVFoundation |
| リアルタイムフィルター | Core Image + Metal Shader |
| 画像処理 | CIFilter（CIColorMatrix, CITemperatureAndTint, CIMotionBlur等） |
| 保存 | Photos Framework |

### UIデザイン方針
- **スキューモーフィズム**: iOS 4〜6時代のカメラアプリUIを忠実に再現
- リアルな質感（金属、革、ガラスの光沢）をSwiftUIカスタム描画で表現
- 標準のiOS UIコンポーネントは使用しない（レトロUIを独自実装）

---

## アーキテクチャ（MVVM）

### フォルダ構成
```
OldIPhoneCameraExperience/
├── OldIPhoneCameraExperienceApp.swift  # エントリーポイント
│
├── Core/                               # 共通基盤
│   ├── Constants/                      # 定数（フィルターパラメータ、サイズ等）
│   ├── Extensions/                     # Swift拡張（CIImage, CGImage等）
│   └── Utils/                          # ユーティリティ関数
│
├── Models/                             # データモデル（Swift struct）
│
├── ViewModels/                         # ViewModel（@Observable class）
│   └── CameraViewModel.swift
│
├── Views/
│   ├── Screens/                        # 画面
│   │   └── CameraScreen.swift          # メイン画面（唯一の画面）
│   └── Components/                     # UIコンポーネント
│       ├── Skeuomorphic/               # スキューモーフィズムUI部品
│       │   ├── ShutterButton.swift      # 金属質感シャッターボタン
│       │   ├── TopToolbar.swift         # iOS 6風ツールバー
│       │   ├── BottomToolbar.swift      # 下部ツールバー
│       │   └── IrisShutter.swift        # 虹彩絞りアニメーション
│       └── Camera/                     # カメラ関連UI
│           └── CameraPreview.swift      # AVCaptureVideoPreviewLayer
│
├── Services/                           # サービス層
│   ├── CameraService.swift             # AVFoundationカメラ制御
│   ├── FilterService.swift             # CIFilterチェーン管理
│   └── PhotoLibraryService.swift       # カメラロール保存
│
└── Resources/                          # リソース
    ├── Assets.xcassets                  # 画像・アイコン・テクスチャ
    └── Sounds/                         # シャッター音等のSE
```

### レイヤー責務

| レイヤー | 責務 | 例 |
|---------|------|-----|
| View (`Views/`) | UI表示、ユーザー入力受付 | SwiftUI View、カスタム描画 |
| ViewModel (`ViewModels/`) | UIロジック、状態管理 | `@Observable class` |
| Service (`Services/`) | ビジネスロジック、デバイス制御 | カメラ制御、フィルター処理、写真保存 |
| Model (`Models/`) | データ構造 | Swift struct |

### 依存関係の方向

```
View → ViewModel → Service → Model
```

- View は ViewModel のみに依存する（Service を直接呼ばない）
- ViewModel は Service 層のみに依存する（View に依存しない）
- Service は Model に依存する
- SwiftUI の `@Environment` / `@State` で依存性を注入する

### ViewModel実装パターン

```swift
import Observation

@Observable
final class CameraViewModel {
    // MARK: - Dependencies
    private let cameraService: CameraService
    private let filterService: FilterService
    private let photoLibraryService: PhotoLibraryService

    // MARK: - State
    var isFlashOn = false
    var isFrontCamera = false
    var isCapturing = false
    var lastCapturedImage: UIImage?

    init(
        cameraService: CameraService = CameraService(),
        filterService: FilterService = FilterService(),
        photoLibraryService: PhotoLibraryService = PhotoLibraryService()
    ) {
        self.cameraService = cameraService
        self.filterService = filterService
        self.photoLibraryService = photoLibraryService
    }

    func capturePhoto() async {
        isCapturing = true
        defer { isCapturing = false }
        // 撮影 → フィルター適用 → 保存
    }

    func toggleFlash() { /* ... */ }
    func toggleCamera() { /* ... */ }
}
```

---

## 実装開始前の必須チェック（最重要）

**Issueの実装を開始する前に、必ず以下のファイルをすべて読むこと。**
これを怠ると、完了済みのIssueを重複実装したり、前提が未完了のIssueに着手してしまうリスクがある。

### Step 1: 現在の進捗を確認する

```
必ず読む: docs/progress.md
```

- **現在のPhase** と **次に着手すべきIssue** を確認する
- 着手しようとしているIssueの前提Issueがすべて ✅ 完了 であることを確認する
- 前提が未完了の場合、そのIssueには着手しない

### Step 2: 実装対象のIssue仕様を確認する

```
必ず読む: docs/implementation-guide.md（該当Issueのセクション）
必ず読む: docs/features.md（該当する機能IDのセクション）
必ず読む: docs/test-cases.md（該当するテストケースID）
```

- implementation-guide.md で「前提・ファイル・作業内容・テストケース」を確認する
- features.md で受け入れ条件を確認する
- test-cases.md でTDD Red Phaseで書くテストの詳細を確認する

### Step 3: アーキテクチャとデータモデルを確認する

```
必ず読む: docs/architecture.md（レイヤー配置・実装パターン）
必ず読む: docs/data-model.md（該当するモデルの定義）
```

### Step 4: 実装完了後にprogress.mdを更新する

- Issue着手時: ステータスを `🔵 進行中` に変更
- PR作成時: PR # を記入
- PRマージ時: ステータスを `✅ 完了` に変更、テスト数・現在のPhaseを更新

---

## Claudeへの指示

### コード実装時
- `@Observable`（Observation framework）を使用してViewModelを実装する
- SwiftUIの標準UIコンポーネントではなく、スキューモーフィズムのカスタムコンポーネントを使う
- AVFoundationのカメラ処理はService層に分離する
- CIFilterのチェーンはFilterServiceに集約する
- 強制アンラップ（`!`）は避け、`guard let` / `if let` を使用する
- `async/await` を使用し、コールバック地獄を避ける

### UIコンポーネント実装時
- すべてのスキューモーフィズムUI部品は `Views/Components/Skeuomorphic/` に配置
- テクスチャ・グラデーション・シャドウはSwiftUIのカスタム描画（`Canvas`、`Shape`、`LinearGradient`等）で実現
- 画像アセットへの依存は最小限にし、コードで描画できるものはコードで描画する

---

## ドキュメント参照（必須）

実装時は必ず以下のドキュメントを参照すること。

### 実装開始前（毎回必須）
- [docs/progress.md](docs/progress.md) - **現在のPhase・Issue進捗**（最初に読む）
- [docs/implementation-guide.md](docs/implementation-guide.md) - 実装手順・Issue詳細・TDDテストケース

### 機能実装時
- [docs/features.md](docs/features.md) - 16機能の詳細仕様・受け入れ条件
- [docs/test-cases.md](docs/test-cases.md) - 81テストケース定義

### 画面実装時
- [docs/screens.md](docs/screens.md) - 画面一覧・UI構成・状態バリエーション

### モデル・データ層実装時
- [docs/data-model.md](docs/data-model.md) - 8つのデータモデル設計
- [docs/architecture.md](docs/architecture.md) - MVVM構成・レイヤー責務・DI方針

### UIデザイン判断時
曖昧な仕様がある場合、以下の優先順で参照して判断すること：
1. [docs/human-interface-guideline.md](docs/human-interface-guideline.md) - UIガイドライン
2. [docs/target-user.md](docs/target-user.md) - ターゲットユーザー
3. [docs/mvp-requirements.md](docs/mvp-requirements.md) - MVP要件

### PR作成前
- [docs/self-review-checklist.md](docs/self-review-checklist.md) - セルフレビューチェック
- [docs/git-rules.md](docs/git-rules.md) - ブランチ・コミット規則

---

## Issue作成ルール（必須）

### 詳細なIssueを作成する場合

詳細なタスク内容を記載するIssueには、**必ずテストケースを含めること**。

#### テストケース作成時の参照ドキュメント

- [docs/test-cases.md](docs/test-cases.md) - テストケース一覧

#### 記載フォーマット例

```markdown
## テストケース

### 1. 〇〇機能
| ID | テストケース | 期待結果 |
|----|-------------|---------|
| T-1.1 | 〇〇を入力する | △△が表示される |
| T-1.2 | □□ボタンを押す | ◇◇が実行される |

### 2. バリデーション
| ID | テストケース | 期待結果 |
|----|-------------|---------|
| T-2.1 | 空欄で送信 | エラーメッセージ表示 |
```

#### 簡易Issueの場合
「詳細は後で入力」のような簡易Issueは、**実装着手前に詳細化すること**。

---

## TDD（テスト駆動開発）

本プロジェクトでは **TDD（Test-Driven Development）** を採用する。

### Red → Green → Refactor サイクル

```
① Red（赤）    ② Green（緑）    ③ Refactor（改善）
   失敗     →     成功      →      改善       → ①に戻る
```

| ステップ | 内容 | やること |
|---------|------|----------|
| **① Red** | テストを書く → **失敗する** | 実装前にテストコードを書く。まだ実装がないので失敗する |
| **② Green** | 最小限のコードを書く → **成功する** | テストが通る最小限の実装を書く。完璧でなくてよい |
| **③ Refactor** | コードを改善 → **成功のまま** | テストが通ったままコードを整理・改善する |

### TDDの実践例

```swift
// ① Red: まずテストを書く（この時点で実装はない → 失敗）
func testFilterServiceAppliesWarmTone() {
    let service = FilterService()
    let inputImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    let result = service.applyIPhone4Filter(to: inputImage)
    XCTAssertNotNil(result)
}

// ② Green: テストが通る最小限の実装を書く
class FilterService {
    func applyIPhone4Filter(to image: CIImage) -> CIImage? {
        let warmFilter = CIFilter(name: "CITemperatureAndTint")
        warmFilter?.setValue(image, forKey: kCIInputImageKey)
        return warmFilter?.outputImage
    }
}

// ③ Refactor: コードを改善（パラメータ調整、メソッド分割など）
```

### TDDを適用する範囲

| 対象 | TDD適用 |
|------|--------|
| Model（データ構造） | ○ |
| ViewModel（UIロジック） | ○ |
| Service（フィルター処理、カメラ制御） | ○ |
| View（SwiftUI） | △（Preview + スナップショットテストは任意） |

### テストファイル配置

```
OldIPhoneCameraExperienceTests/
├── Models/              # Modelのテスト
├── ViewModels/          # ViewModelのテスト
└── Services/            # Serviceのテスト
    ├── FilterServiceTests.swift
    ├── CameraServiceTests.swift
    └── PhotoLibraryServiceTests.swift
```

---

## 実装ワークフロー

### Phase 1: 実装前チェック（必須）

実装を開始する前に、以下を確認する：

| # | チェック項目 | 確認内容 |
|---|-------------|----------|
| 1 | **要件の明確さ** | Issueに曖昧な要件がないか？不明点があればユーザーに確認する |
| 2 | **テストケースの存在** | Issueにテストケース（ID付きテーブル）が記載されているか？ |

**テストケースがない場合:** 実装前にユーザーへ報告し、テストケースを作成してもらうか、自分で作成して承認を得る。

---

### Phase 1.5: テストコード作成（TDD - Red）

Issueのテストケースに基づいて、**実装前に**テストコードを書く。

**この時点でテストを実行すると失敗する（Red）** → 正常

---

### Phase 2: 実装（TDD - Green）

テストが通る最小限のコードを実装する。

```bash
# テスト実行で成功を確認
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16'
```

**すべてのテストが通ったら（Green）** → Phase 2.5へ

---

### Phase 2.5: リファクタリング（TDD - Refactor）

テストが通ったまま、コードを改善する：

- 変数名・メソッド名の改善
- 重複コードの削除
- 可読性の向上

```bash
# リファクタリング後もテストが通ることを確認
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

### Phase 3: PR作成前チェック（必須）

実装が完了したら、PR作成前に以下を**順番に**実行する。

#### 1. セルフレビューチェック

[docs/self-review-checklist.md](docs/self-review-checklist.md) の項目を確認する。

#### 2. 自動チェックコマンド

```bash
# 1. ビルド確認
xcodebuild build -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16'

# 2. 全テスト実行
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16'

# 3. SwiftLint
swiftlint

# 4. SwiftFormat（コードフォーマット）
swiftformat .
```

- Lintエラーがある場合は、**自動的に修正してOK**（ユーザー確認不要）
- SwiftFormatによる整形差分がある場合は、**自動的にコミットしてOK**（ユーザー確認不要）
- テストが失敗した場合は、修正してから次へ進む

**すべて通過したら** コミット・PR作成へ進む。

---

### Phase 4: PR作成後チェック（必須）

PRを作成した後、以下を確認する：

```bash
gh pr checks <PR番号>        # GitHub Actionsの結果
gh api repos/{owner}/{repo}/pulls/<PR番号>/comments  # レビューコメント
```

- GitHub Actionsが失敗している場合、エラー内容を確認して修正
- レビューコメントがある場合：
  - **必ずユーザーに内容を報告する**
  - **修正内容を説明し、ユーザーの承認を得てから修正を行う**

---

### Phase 5: PRマージ（「PR #XXをマージして」と言われた場合）

以下の手順を実行する：

```bash
# 1. ローカル変更があればstash
git stash

# 2. PRのブランチに切り替え
git checkout <ブランチ名>

# 3. ターゲットブランチ（通常はdevelop）の最新を取り込む
git fetch origin
git merge origin/develop

# 4. コンフリクトがあれば解決してコミット
# コンフリクトがなければそのままプッシュ
git push origin <ブランチ名>

# 5. PRをsquashマージしてブランチ削除
gh pr merge <PR番号> --squash --delete-branch

# 6. developブランチに切り替えて最新を取得
git checkout develop && git pull origin develop

# 7. マージ済みブランチの削除確認
git branch -d <ブランチ名> 2>/dev/null || echo "ローカルブランチは既に削除済み"
git push origin --delete <ブランチ名> 2>/dev/null || echo "リモートブランチは既に削除済み"
```

マージ完了後、次のタスク候補を提案する。

---

## バグ対応ワークフロー

バグ報告を受けた場合、**いきなり修正せず**、以下の手順で対応する。

### Step 1: 調査（必須）

まず原因を特定するための調査を行う：

```
1. バグの再現条件を確認
2. 関連するソースコードを読む
3. データフロー・状態遷移を追跡
4. 類似のバグや関連するIssue/PRがないか確認
```

### Step 2: 判断分岐

調査結果に基づいて、以下のいずれかを選択する：

| 状況 | アクション |
|------|-----------|
| **原因が特定でき、自信を持って修正できる** | → 修正内容をユーザーに提案し、承認後に修正 |
| **原因の候補はあるが確信が持てない** | → デバッグログ追加を提案（Step 3へ） |
| **原因がまったく分からない** | → 調査で分かったことを報告し、追加情報をユーザーに求める |

### Step 3: デバッグログ追加の提案

確信が持てない場合、以下の形式でデバッグログ追加を提案する：

```markdown
## 調査結果
- 確認したファイル: `Services/CameraService.swift`, `ViewModels/CameraViewModel.swift`
- 現時点の仮説: 〇〇が△△のタイミングで□□になっている可能性

## デバッグログ追加の提案
以下の箇所にログを追加して、実際の動作を確認させてください：

1. `Services/CameraService.swift:XX行目` - 〇〇の値を確認
2. `ViewModels/CameraViewModel.swift:YY行目` - △△のタイミングを確認
```

**ユーザーの承認後**、デバッグログを追加し、ユーザーに再現手順の実行を依頼する。

---

## ブランチルール

[docs/git-rules.md](docs/git-rules.md) を参照。
