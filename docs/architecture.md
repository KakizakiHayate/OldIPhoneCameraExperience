# アーキテクチャ

本ドキュメントはプロジェクトのアーキテクチャ設計を定義する。

---

## 1. アーキテクチャパターン: MVVM

### パターン概要

| 項目 | 内容 |
|------|------|
| パターン | MVVM（Model-View-ViewModel） |
| 状態管理 | Observation framework（`@Observable`） |
| UIフレームワーク | SwiftUI（カスタムスキューモーフィズムUI） |
| 依存性注入 | イニシャライザ注入 + SwiftUI `@Environment` |

### データフロー

```
┌─────────────────────────────────────────────────────┐
│                 View（Screens / Components）          │
│  - @State / @Environment でViewModelを参照            │
│  - ユーザー操作をViewModelのメソッド呼び出しに変換      │
│  - ViewModelの状態変化で自動的に再描画される            │
└──────────────────────┬──────────────────────────────┘
                       │ ユーザー操作
                       ▼
┌─────────────────────────────────────────────────────┐
│              ViewModel（@Observable class）           │
│  - UIロジック・状態管理                                │
│  - Service層のメソッドを呼び出す                       │
│  - Viewに依存しない（UIKitやSwiftUIのimportは最小限）  │
└──────────────────────┬──────────────────────────────┘
                       │ データ操作
                       ▼
┌─────────────────────────────────────────────────────┐
│                 Service（ビジネスロジック）             │
│  - デバイス制御（カメラ、モーションセンサー）           │
│  - フィルター処理（CIFilterチェーン）                  │
│  - 外部フレームワークとの接続（AVFoundation, Photos等） │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│                 Model（データ構造）                    │
│  - 純粋なSwift struct                                │
│  - ビジネスロジックを持たない                          │
└─────────────────────────────────────────────────────┘
```

### 依存関係の方向（厳守）

```
View → ViewModel → Service → Model
```

| ルール | 内容 |
|--------|------|
| View → ViewModel | View は ViewModel のみに依存する。Service を直接呼ばない |
| ViewModel → Service | ViewModel は Service 層のみに依存する。View に依存しない |
| Service → Model | Service は Model に依存する。ViewModel に依存しない |
| Model → なし | Model はどの層にも依存しない（純粋なデータ構造） |

**禁止パターン:**
- View が Service を直接呼び出す
- ViewModel が View を参照する（`SwiftUI.View` や `UIKit` に依存する）
- Service が ViewModel を参照する
- 下位層が上位層に依存する（逆方向の依存）

---

## 2. フォルダ構成

```
OldIPhoneCameraExperience/
├── OldIPhoneCameraExperienceApp.swift  # エントリーポイント
│
├── Core/                               # 共通基盤（全レイヤーから参照可能）
│   ├── Constants/                      # 定数
│   │   ├── FilterParameters.swift      # フィルターパラメータ定数
│   │   ├── CameraConfig.swift          # カメラ設定定数
│   │   └── UIConstants.swift           # UI関連定数（サイズ、余白、色）
│   ├── Extensions/                     # Swift標準型の拡張
│   │   ├── CIImage+Extensions.swift    # CIImage拡張
│   │   └── Color+Extensions.swift      # SwiftUI Color拡張
│   └── Utils/                          # ユーティリティ関数
│
├── Models/                             # データモデル（純粋なstruct）
│   ├── CaptureState.swift              # 撮影状態
│   └── FilterConfig.swift              # フィルター設定値
│
├── ViewModels/                         # ViewModel（@Observable class）
│   └── CameraViewModel.swift           # メインViewModel
│
├── Views/
│   ├── Screens/                        # 画面（1画面のみ）
│   │   └── CameraScreen.swift          # メイン画面
│   └── Components/                     # UIコンポーネント
│       ├── Skeuomorphic/               # スキューモーフィズムUI部品
│       │   ├── ShutterButton.swift      # 金属質感シャッターボタン
│       │   ├── TopToolbar.swift         # iOS 6風ツールバー
│       │   ├── BottomToolbar.swift      # 下部ツールバー
│       │   └── IrisShutter.swift        # 虹彩絞りアニメーション
│       └── Camera/                     # カメラ関連UI
│           └── CameraPreview.swift      # フィルター適用済みプレビュー
│
├── Services/                           # サービス層
│   ├── CameraService.swift             # AVFoundationカメラ制御
│   ├── FilterService.swift             # CIFilterチェーン管理
│   ├── PhotoLibraryService.swift       # カメラロール保存
│   └── MotionService.swift             # CoreMotionジャイロスコープ
│
└── Resources/                          # リソース
    ├── Assets.xcassets                  # 画像・アイコン・テクスチャ
    └── Sounds/                         # シャッター音SE
```

### テストフォルダ構成

`lib/` の構造をミラーリングする（paste_keyboardと同じ方針）。

```
OldIPhoneCameraExperienceTests/
├── Models/                             # Modelのテスト
│   ├── CaptureStateTests.swift
│   └── FilterConfigTests.swift
├── ViewModels/                         # ViewModelのテスト
│   └── CameraViewModelTests.swift
├── Services/                           # Serviceのテスト
│   ├── FilterServiceTests.swift
│   ├── CameraServiceTests.swift
│   ├── PhotoLibraryServiceTests.swift
│   └── MotionServiceTests.swift
└── Core/                               # Core層のテスト
    └── Constants/
        └── FilterParametersTests.swift
```

---

## 3. 各レイヤーの責務と実装パターン

### 3.1 Model層（`Models/`）

**責務:** 純粋なデータ構造。ビジネスロジックを持たない。

**実装ルール:**
- `struct` で定義する（`class` は使わない）
- すべてのプロパティは `let`（イミュータブル）
- 値の更新が必要な場合は新しいインスタンスを生成する
- ビジネスロジック・副作用を持たない

**実装パターン:**

```swift
struct FilterConfig {
    // MARK: - Properties
    let warmthIntensity: Double
    let saturation: Double
    let cropRatio: Double
    let outputWidth: Int
    let outputHeight: Int

    // MARK: - Default Values
    static let `default` = FilterConfig(
        warmthIntensity: 1000,
        saturation: 0.9,
        cropRatio: 0.81,
        outputWidth: 2592,
        outputHeight: 1936
    )
}
```

### 3.2 Service層（`Services/`）

**責務:** 外部フレームワークとの接続、デバイス制御、ビジネスロジック。

**実装ルール:**
- 1サービス = 1責務（単一責任の原則）
- ViewModelやViewに依存しない
- `async/await` を使用する（コールバックは使わない）
- テスタビリティのため、protocolを定義してDIできるようにする

**実装パターン:**

```swift
// MARK: - Protocol定義（テスト時にモック差し替え可能）
protocol CameraServiceProtocol {
    func startSession() async throws
    func stopSession()
    func capturePhoto() async throws -> CIImage
    func switchCamera() async throws
    func setFlash(enabled: Bool)
}

// MARK: - 実装
final class CameraService: CameraServiceProtocol {
    private let captureSession = AVCaptureSession()
    private var currentDevice: AVCaptureDevice?

    func startSession() async throws {
        // AVCaptureSessionの構成・開始
    }

    func capturePhoto() async throws -> CIImage {
        // 写真キャプチャ → CIImage返却
    }

    // ...
}
```

**サービス一覧と責務:**

| サービス | 責務 | 外部フレームワーク |
|---------|------|-------------------|
| `CameraService` | カメラセッション管理、撮影、フラッシュ、カメラ切り替え | AVFoundation |
| `FilterService` | CIFilterチェーン構築、フィルター適用 | Core Image |
| `PhotoLibraryService` | カメラロールへの保存、最新写真の取得、パーミッション管理 | Photos Framework |
| `MotionService` | ジャイロスコープデータの取得 | CoreMotion |

### 3.3 ViewModel層（`ViewModels/`）

**責務:** UIロジック、状態管理。ViewとServiceの橋渡し。

**実装ルール:**
- `@Observable final class` で定義する
- Service層への依存はイニシャライザ注入する（テスト時にモック差し替え可能）
- View固有の型（`SwiftUI.View`、`UIViewController`等）に依存しない
- `@MainActor` を付けてメインスレッドでの状態更新を保証する

**実装パターン:**

```swift
import Observation

@MainActor
@Observable
final class CameraViewModel {
    // MARK: - Dependencies（イニシャライザ注入）
    private let cameraService: CameraServiceProtocol
    private let filterService: FilterServiceProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let motionService: MotionServiceProtocol

    // MARK: - UI State（Viewが参照する状態）
    var isFlashOn = false
    var isFrontCamera = false
    var isCapturing = false
    var lastCapturedImage: UIImage?
    var permissionDenied = false

    // MARK: - Init
    init(
        cameraService: CameraServiceProtocol = CameraService(),
        filterService: FilterServiceProtocol = FilterService(),
        photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
        motionService: MotionServiceProtocol = MotionService()
    ) {
        self.cameraService = cameraService
        self.filterService = filterService
        self.photoLibraryService = photoLibraryService
        self.motionService = motionService
    }

    // MARK: - Actions（Viewから呼ばれるメソッド）
    func capturePhoto() async {
        isCapturing = true
        defer { isCapturing = false }

        // 1. 撮影
        // 2. フィルター適用
        // 3. 保存
        // 4. サムネイル更新
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraService.setFlash(enabled: isFlashOn)
    }

    func toggleCamera() async {
        // カメラ切り替え + フラッシュ状態リセット
    }
}
```

**ViewModelに入れるもの / 入れないもの:**

| ViewModelに入れる | ViewModelに入れない |
|------------------|-------------------|
| UI状態の管理（isCapturing等） | Widget/Viewの構築 |
| Service層のメソッド呼び出し | アラート・ダイアログの表示 |
| ビジネスロジックの調整 | ナビゲーション処理 |
| エラーハンドリング | アニメーション制御 |

### 3.4 View層（`Views/`）

**責務:** UI表示、ユーザー入力の受付。ロジックを持たない。

**実装ルール:**
- ViewModelの状態を参照してUIを構築する
- ユーザー操作はViewModelのメソッド呼び出しに変換する
- View自体にビジネスロジックを書かない
- スキューモーフィズムUIはすべてSwiftUIカスタム描画で実装する

**実装パターン:**

```swift
struct CameraScreen: View {
    @State private var viewModel = CameraViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TopToolbar(
                isFlashOn: viewModel.isFlashOn,
                isFrontCamera: viewModel.isFrontCamera,
                onFlashToggle: { viewModel.toggleFlash() },
                onCameraToggle: { Task { await viewModel.toggleCamera() } }
            )

            CameraPreview(/* ... */)

            BottomToolbar(
                isCapturing: viewModel.isCapturing,
                lastPhoto: viewModel.lastCapturedImage,
                onShutter: { Task { await viewModel.capturePhoto() } }
            )
        }
        .prefersStatusBarHidden(true)
    }
}
```

**Componentの設計方針:**

| 方針 | 内容 |
|------|------|
| データ渡し | ViewModelを直接渡さず、必要なプロパティ・クロージャを個別に渡す |
| 再利用性 | 各ComponentはViewModelに依存せず、単体でPreview可能にする |
| カスタム描画 | 標準UIコンポーネントは使わず、SwiftUIのShape/Canvas/Gradientで描画する |

---

## 4. 依存性注入（DI）

### 方針

paste_keyboardではRiverpod Providerを使用しているが、本プロジェクトではSwift標準の**イニシャライザ注入**を採用する。

### パターン

**本番コード:**

```swift
// デフォルト引数で本番実装を注入
let viewModel = CameraViewModel()
// ↑ 内部で CameraService(), FilterService() 等が自動注入される
```

**テストコード:**

```swift
// Protocol準拠のモックを注入
let viewModel = CameraViewModel(
    cameraService: MockCameraService(),
    filterService: MockFilterService(),
    photoLibraryService: MockPhotoLibraryService(),
    motionService: MockMotionService()
)
```

### Protocol定義の配置

Protocolは対応するServiceファイル内に定義する（別ファイルにはしない）。

```
Services/
├── CameraService.swift         # CameraServiceProtocol + CameraService
├── FilterService.swift         # FilterServiceProtocol + FilterService
├── PhotoLibraryService.swift   # PhotoLibraryServiceProtocol + PhotoLibraryService
└── MotionService.swift         # MotionServiceProtocol + MotionService
```

---

## 5. Core層（`Core/`）

全レイヤーから参照可能な共通基盤。paste_keyboardの`core/`と同じ役割。

### 5.1 Constants（`Core/Constants/`）

**方針:** マジックナンバー・マジックストリングを排除し、定数を一元管理する。

**FilterParameters.swift** — フィルター関連の定数:

```swift
enum FilterParameters {
    // 暖色系色味（F2.1）
    static let warmthShift: CGFloat = 1000       // 色温度シフト（K相当）
    static let saturation: CGFloat = 0.9         // 彩度（1.0が標準）
    static let highlightTintAmount: CGFloat = 0.1 // ハイライトティント強度

    // 画角クロップ（F2.2）
    static let cropRatio: CGFloat = 0.81         // 26mm→32mm換算
    static let outputWidth: Int = 2592           // 出力幅（px）
    static let outputHeight: Int = 1936          // 出力高さ（px）

    // 手ブレシミュレーション（F2.3）
    static let shakeShiftRange: ClosedRange<CGFloat> = 1...5       // シフト量（px）
    static let shakeRotationRange: ClosedRange<CGFloat> = -0.5...0.5 // 回転角度（度）
    static let motionBlurRadiusRange: ClosedRange<CGFloat> = 1.0...3.0 // ブラー半径
}
```

**CameraConfig.swift** — カメラ設定の定数:

```swift
enum CameraConfig {
    static let defaultPosition: AVCaptureDevice.Position = .back
    static let sessionPreset: AVCaptureSession.Preset = .photo
    static let previewAspectRatio: CGFloat = 4.0 / 3.0
    static let targetFPS: Int = 30
}
```

**UIConstants.swift** — UI関連の定数:

```swift
enum UIConstants {
    // ツールバー
    static let topToolbarHeight: CGFloat = 44
    static let bottomToolbarHeight: CGFloat = 96

    // シャッターボタン
    static let shutterButtonSize: CGFloat = 66
    static let shutterButtonInnerSize: CGFloat = 54

    // サムネイル
    static let thumbnailSize: CGFloat = 44
    static let thumbnailCornerRadius: CGFloat = 4

    // アニメーション
    static let irisCloseDuration: TimeInterval = 0.2
    static let irisOpenDuration: TimeInterval = 0.3
    static let flashFadeDuration: TimeInterval = 0.15
}
```

### 5.2 Extensions（`Core/Extensions/`）

**方針:** Swift標準型やフレームワーク型の拡張を配置する。アプリ固有のロジックは含めない。

### 5.3 Utils（`Core/Utils/`）

**方針:** 複数のレイヤーから使用されるユーティリティ関数。特定のレイヤーに属さない汎用処理。

---

## 6. 状態管理

### 使用技術

| 技術 | 用途 |
|------|------|
| `@Observable` (Observation framework) | ViewModelの状態管理 |
| `@State` | View内のViewModelインスタンス保持 |
| `@Environment` | ViewModelの子Viewへの受け渡し（必要な場合） |
| `@Binding` | 親Viewから子Componentへのプロパティ受け渡し |

### 状態の種類と管理場所

| 状態の種類 | 管理場所 | 例 |
|-----------|---------|-----|
| アプリ状態 | ViewModel | `isFlashOn`, `isFrontCamera`, `isCapturing` |
| UI一時状態 | View（@State） | アニメーション中フラグ、ボタン押下状態 |
| デバイス状態 | Service | カメラセッション状態、ジャイロデータ |

### paste_keyboardとの対応表

| paste_keyboard (Flutter/Riverpod) | 本プロジェクト (Swift/SwiftUI) |
|-----------------------------------|-------------------------------|
| `StateNotifier<T>` | `@Observable class` |
| `StateNotifierProvider` | `@State` + イニシャライザ |
| `ref.watch()` | SwiftUIの自動再描画（@Observableの変更検知） |
| `ref.read().notifier.method()` | `viewModel.method()` |
| `Provider<Service>` | イニシャライザ注入（デフォルト引数） |
| `ProviderContainer` (テスト) | イニシャライザにモックを注入 |

---

## 7. テスト方針

### TDD（テスト駆動開発）

Red → Green → Refactor サイクルを遵守する。

### テスト対象と方針

| レイヤー | テスト対象 | テスト方法 |
|---------|-----------|-----------|
| Model | データ構造の生成・デフォルト値 | XCTest（純粋なユニットテスト） |
| ViewModel | UIロジック・状態遷移 | XCTest + Serviceのモック注入 |
| Service | ビジネスロジック・フィルター処理 | XCTest + フレームワークのモック |
| Core/Constants | 定数値の妥当性 | XCTest |
| View | - | Xcode Preview での目視確認（自動テスト対象外） |

### モックの実装パターン

```swift
// テスト用モック
final class MockCameraService: CameraServiceProtocol {
    var startSessionCalled = false
    var capturePhotoCalled = false
    var flashEnabled = false
    var stubbedImage: CIImage?

    func startSession() async throws {
        startSessionCalled = true
    }

    func capturePhoto() async throws -> CIImage {
        capturePhotoCalled = true
        guard let image = stubbedImage else {
            throw CameraError.captureFailure
        }
        return image
    }

    // ...
}
```

### テストの命名規則

```swift
// パターン: test_[メソッド名]_[条件]_[期待結果]
func test_capturePhoto_whenSessionActive_savesToPhotoLibrary() async {
    // ...
}

func test_toggleFlash_whenFrontCamera_doesNotEnable() {
    // ...
}
```

---

## 8. アーキテクチャ判断基準

新しいコードを書くときに「どの層に置くか」迷った場合の判断基準。

| 質問 | YES → | NO → |
|------|-------|------|
| UIの見た目に関係するか？ | View層 | 次へ |
| UIの状態やユーザー操作のハンドリングか？ | ViewModel層 | 次へ |
| 外部フレームワーク（AVFoundation等）を使うか？ | Service層 | 次へ |
| データの構造定義か？ | Model層 | 次へ |
| 複数レイヤーから使う定数・ユーティリティか？ | Core層 | 設計を見直す |
