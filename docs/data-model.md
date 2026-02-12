# データモデル設計

本ドキュメントはアプリで使用するデータモデル（Swift struct）を定義する。

---

## 設計方針

| 方針 | 内容 |
|------|------|
| 実装 | すべて `struct`（イミュータブル） |
| 永続化（MVP） | なし。撮影写真はカメラロール（Photos Framework）に保存するのみ |
| 永続化（Phase 2） | SwiftData等でメタデータを永続化予定。そのため、MVPの段階からPhase 2を想定した構造にしておく |
| 配置先 | `Models/` フォルダ |

---

## モデル一覧

| # | モデル名 | 用途 | MVP | Phase 2 |
|---|---------|------|-----|---------|
| 1 | [CameraState](#1-camerastate) | カメラの現在の状態 | ○ | ○ |
| 2 | [CaptureResult](#2-captureresult) | 撮影結果データ | ○ | ○ |
| 3 | [FilterConfig](#3-filterconfig) | フィルターパラメータセット | ○ | ○ |
| 4 | [ShakeEffect](#4-shakeeffect) | 手ブレシミュレーションのパラメータ | ○ | ○ |
| 5 | [CameraModel](#5-cameramodel) | 再現する機種の定義 | △（iPhone 4固定） | ○ |
| 6 | [PhotoMetadata](#6-photometadata-phase-2) | 撮影メタデータ（永続化用） | × | ○ |
| 7 | [UserPreferences](#7-userpreferences-phase-2) | ユーザー設定（選択中の機種等） | × | ○ |
| 8 | [PurchaseState](#8-purchasestate-phase-2) | 課金・アンロック状態 | × | ○ |

---

## 1. CameraState

カメラの現在の動作状態を表す。ViewModelが保持し、Viewが参照する。

### 定義

```swift
struct CameraState {
    let isFlashOn: Bool
    let cameraPosition: CameraPosition
    let isCapturing: Bool
    let permissionStatus: PermissionStatus
}
```

### プロパティ

| プロパティ | 型 | 説明 | デフォルト値 |
|-----------|-----|------|-------------|
| `isFlashOn` | `Bool` | フラッシュのオン/オフ状態 | `false` |
| `cameraPosition` | `CameraPosition` | 使用中のカメラ（前面/背面） | `.back` |
| `isCapturing` | `Bool` | 撮影処理中かどうか | `false` |
| `permissionStatus` | `PermissionStatus` | カメラ権限の状態 | `.notDetermined` |

### 関連Enum

```swift
enum CameraPosition {
    case front
    case back
}

enum PermissionStatus {
    case notDetermined  // 未決定（初回起動前）
    case authorized     // 許可済み
    case denied         // 拒否
}
```

### 使用箇所

| 参照元 | 用途 |
|--------|------|
| `CameraViewModel` | 状態管理 |
| `CameraScreen` (S-1) | 状態バリエーション表示（S-1a〜S-1e） |
| `TopToolbar` (F3.1) | フラッシュボタン表示/非表示、カメラ切替状態 |
| `ShutterButton` (F3.3) | 撮影中の無効化 |

---

## 2. CaptureResult

撮影結果を表す。撮影〜フィルター適用〜保存のパイプラインで使用する。

### 定義

```swift
struct CaptureResult {
    let image: UIImage
    let filterConfig: FilterConfig
    let shakeEffect: ShakeEffect?
    let capturedAt: Date
    let cameraPosition: CameraPosition
    let flashUsed: Bool
    let cameraModel: CameraModel
}
```

### プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `image` | `UIImage` | フィルター適用済みの最終画像 |
| `filterConfig` | `FilterConfig` | 適用されたフィルター設定 |
| `shakeEffect` | `ShakeEffect?` | 適用された手ブレパラメータ（nilの場合はブレなし） |
| `capturedAt` | `Date` | 撮影日時 |
| `cameraPosition` | `CameraPosition` | 撮影時のカメラ（前面/背面） |
| `flashUsed` | `Bool` | フラッシュ使用の有無 |
| `cameraModel` | `CameraModel` | 使用した再現機種 |

### 使用箇所

| 参照元 | 用途 |
|--------|------|
| `CameraViewModel` | 撮影処理の結果として生成 |
| `PhotoLibraryService` | カメラロールへの保存 |
| `BottomToolbar` (F3.5) | 直近撮影サムネイルの更新 |

### Phase 2での拡張

`PhotoMetadata` への変換メソッドを追加予定（永続化用）。

---

## 3. FilterConfig

フィルターのパラメータセットを表す。機種ごとに異なる設定値を持つ。

### 定義

```swift
struct FilterConfig {
    // 暖色系の色味（F2.1）
    let warmth: Double
    let tint: Double
    let saturation: Double
    let highlightTintIntensity: Double

    // 画角クロップ（F2.2）
    let cropRatio: Double
    let outputWidth: Int
    let outputHeight: Int
}
```

### プロパティ

| プロパティ | 型 | 説明 | iPhone 4の値 |
|-----------|-----|------|-------------|
| `warmth` | `Double` | 色温度シフト量 | `1000`（暖色方向） |
| `tint` | `Double` | ティント（緑-マゼンタ方向） | `10`（やや暖色） |
| `saturation` | `Double` | 彩度（1.0が標準） | `0.9`（やや減） |
| `highlightTintIntensity` | `Double` | ハイライトへのオレンジティント強度 | `0.1` |
| `cropRatio` | `Double` | クロップ率（1.0でクロップなし） | `0.81`（26mm→32mm） |
| `outputWidth` | `Int` | 出力画像の幅（px） | `2592` |
| `outputHeight` | `Int` | 出力画像の高さ（px） | `1936` |

### プリセット

```swift
extension FilterConfig {
    /// iPhone 4 のフィルター設定（MVP）
    static let iPhone4 = FilterConfig(
        warmth: 1000,
        tint: 10,
        saturation: 0.9,
        highlightTintIntensity: 0.1,
        cropRatio: 0.81,
        outputWidth: 2592,
        outputHeight: 1936
    )
}
```

### 使用箇所

| 参照元 | 用途 |
|--------|------|
| `FilterService` | CIFilterチェーンの構築時にパラメータとして使用 |
| `CameraViewModel` | 現在の機種に応じたFilterConfigの選択 |
| `CaptureResult` | 撮影結果に適用されたフィルター設定を記録 |

### Phase 2での拡張

機種追加時に新しいプリセットを追加する。

```swift
extension FilterConfig {
    static let iPhone5s = FilterConfig(
        warmth: 800,
        tint: 5,
        saturation: 0.92,
        highlightTintIntensity: 0.08,
        cropRatio: 0.85,       // 30mm相当
        outputWidth: 3264,     // 8MP
        outputHeight: 2448
    )

    static let iPhone6 = FilterConfig(/* ... */)
}
```

---

## 4. ShakeEffect

手ブレシミュレーションの1回分のパラメータを表す。撮影ごとにランダム生成される。

### 定義

```swift
struct ShakeEffect {
    let shiftX: Double
    let shiftY: Double
    let rotation: Double
    let motionBlurRadius: Double
    let motionBlurAngle: Double
}
```

### プロパティ

| プロパティ | 型 | 説明 | 値の範囲 |
|-----------|-----|------|---------|
| `shiftX` | `Double` | X方向のシフト量（px） | 1〜5 |
| `shiftY` | `Double` | Y方向のシフト量（px） | 1〜5 |
| `rotation` | `Double` | 回転角度（度） | -0.5〜+0.5 |
| `motionBlurRadius` | `Double` | モーションブラーの半径 | 1.0〜3.0 |
| `motionBlurAngle` | `Double` | モーションブラーの角度（度）。ジャイロスコープから算出 | 0〜360 |

### ファクトリメソッド

```swift
extension ShakeEffect {
    /// ジャイロスコープのデータからShakeEffectを生成する
    /// - Parameter deviceMotion: CoreMotionから取得したデバイスの動き
    /// - Returns: ランダム要素を含む手ブレパラメータ
    static func generate(from deviceMotion: CMDeviceMotion?) -> ShakeEffect {
        // ジャイロデータからブレ方向を算出
        // ランダム要素を加えて自然なブレを生成
    }
}
```

### 使用箇所

| 参照元 | 用途 |
|--------|------|
| `FilterService` | 撮影時にCIAffineTransform + CIMotionBlurのパラメータとして使用 |
| `MotionService` | ジャイロスコープデータからShakeEffectを生成 |
| `CaptureResult` | 撮影結果に適用されたブレパラメータを記録 |

---

## 5. CameraModel

再現するiPhone機種の定義。MVPではiPhone 4固定だが、Phase 2で複数機種に拡張する。

**注意:** 購入状態（`isPurchased`）はこのモデルには持たせない。購入状態はユーザーデータ（`PurchaseState`）で管理する。機種の定義（マスターデータ）とユーザーの購入状態を分離することで、課金モデルの変更（買い切り↔サブスク）に柔軟に対応できる。

### 定義

```swift
struct CameraModel: Identifiable {
    let id: String
    let name: String
    let year: Int
    let megapixels: Double
    let focalLengthEquivalent: Double
    let supportedIOSRange: String
    let filterConfig: FilterConfig
    let isFree: Bool
}
```

### プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `id` | `String` | 一意の識別子（例: `"iphone4"`） |
| `name` | `String` | 表示名（例: `"iPhone 4"`） |
| `year` | `Int` | 発売年（例: `2010`） |
| `megapixels` | `Double` | カメラの画素数（例: `5.0`） |
| `focalLengthEquivalent` | `Double` | 35mm換算焦点距離（例: `32.0`） |
| `supportedIOSRange` | `String` | 対応iOSバージョン（例: `"4〜7"`） |
| `filterConfig` | `FilterConfig` | この機種のフィルター設定 |
| `isFree` | `Bool` | 無料で使えるか（iPhone 4はtrue、他はfalse） |

### プリセット

```swift
extension CameraModel {
    /// iPhone 4（MVPで使用。無料）
    static let iPhone4 = CameraModel(
        id: "iphone4",
        name: "iPhone 4",
        year: 2010,
        megapixels: 5.0,
        focalLengthEquivalent: 32.0,
        supportedIOSRange: "4〜7",
        filterConfig: .iPhone4,
        isFree: true
    )

    /// 全機種一覧（Phase 2で追加）
    static let allModels: [CameraModel] = [
        .iPhone4,
        // .iPhone5s,
        // .iPhone6,
        // ...
    ]
}
```

### MVPでの扱い

MVPではiPhone 4固定のため、CameraModelを直接UIに露出させない。ただし内部的には`CameraModel.iPhone4`を使用し、Phase 2での機種切り替えに備える。

```swift
// MVP: ViewModelで固定
let currentModel: CameraModel = .iPhone4
```

### Phase 2での拡張

画面S-4（機種選択）・S-5（機種詳細）で使用。機種一覧の取得、選択切り替えを行う。購入状態は `PurchaseState` から取得する。

### 機種がアンロック済みかの判定（Phase 2）

```swift
// CameraModel自体は購入状態を持たない
// PurchaseStateと組み合わせて判定する
func isUnlocked(model: CameraModel, purchaseState: PurchaseState) -> Bool {
    if model.isFree { return true }
    if purchaseState.hasActiveSubscription { return true }
    return purchaseState.purchasedModelIds.contains(model.id)
}
```

---

## 6. PhotoMetadata（Phase 2）

撮影した写真のメタデータ。Phase 2でSwiftData等に永続化する。

### 定義

```swift
struct PhotoMetadata: Identifiable {
    let id: UUID
    let capturedAt: Date
    let cameraModelId: String
    let cameraPosition: CameraPosition
    let flashUsed: Bool
    let filterConfig: FilterConfig
    let shakeEffect: ShakeEffect?
    let photoLibraryIdentifier: String
}
```

### プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `id` | `UUID` | 一意の識別子 |
| `capturedAt` | `Date` | 撮影日時 |
| `cameraModelId` | `String` | 使用した機種のID |
| `cameraPosition` | `CameraPosition` | 前面/背面 |
| `flashUsed` | `Bool` | フラッシュ使用の有無 |
| `filterConfig` | `FilterConfig` | 適用されたフィルター設定 |
| `shakeEffect` | `ShakeEffect?` | 適用された手ブレパラメータ |
| `photoLibraryIdentifier` | `String` | Photos Frameworkのローカル識別子（カメラロールとの紐付け用） |

### MVPでの扱い

MVPでは使用しない。`CaptureResult` から `PhotoMetadata` への変換は Phase 2 で実装する。

### Phase 2での用途

- ギャラリー画面（S-6）での一覧表示・機種フィルタリング
- 写真詳細画面（S-7）での撮影情報表示

---

## 7. UserPreferences（Phase 2）

ユーザーの設定・選択状態。Phase 2でUserDefaults等に永続化する。

### 定義

```swift
struct UserPreferences {
    let selectedCameraModelId: String
    let hasCompletedOnboarding: Bool
}
```

### プロパティ

| プロパティ | 型 | 説明 | デフォルト値 |
|-----------|-----|------|-------------|
| `selectedCameraModelId` | `String` | 現在選択中の機種ID | `"iphone4"` |
| `hasCompletedOnboarding` | `Bool` | オンボーディング完了済みか | `false` |

### デフォルト値

```swift
extension UserPreferences {
    static let `default` = UserPreferences(
        selectedCameraModelId: CameraModel.iPhone4.id,
        hasCompletedOnboarding: false
    )
}
```

### MVPでの扱い

MVPでは使用しない。選択機種はiPhone 4固定のため、ViewModelでハードコードする。

### Phase 2での用途

- 機種選択画面（S-4）で選択した機種の記憶
- アプリ再起動時に前回の設定を復元
- UserDefaultsで永続化

---

## 8. PurchaseState（Phase 2）

課金・アンロック状態。買い切り（機種単位）とサブスクリプション（全機種アンロック）の両方に対応できる構造。

### 定義

```swift
struct PurchaseState {
    let purchasedModelIds: Set<String>
    let hasActiveSubscription: Bool
    let subscriptionExpiresAt: Date?
}
```

### プロパティ

| プロパティ | 型 | 説明 |
|-----------|-----|------|
| `purchasedModelIds` | `Set<String>` | 買い切りで購入済みの機種ID一覧 |
| `hasActiveSubscription` | `Bool` | サブスクリプションが有効か |
| `subscriptionExpiresAt` | `Date?` | サブスク有効期限（nilの場合は買い切りのみ） |

### デフォルト値

```swift
extension PurchaseState {
    /// 初期状態（未課金）
    static let `default` = PurchaseState(
        purchasedModelIds: [],
        hasActiveSubscription: false,
        subscriptionExpiresAt: nil
    )
}
```

### 課金モデルとの対応

| 課金モデル | 判定ロジック |
|-----------|-------------|
| **買い切り（機種単位）** | `purchasedModelIds.contains(model.id)` で判定 |
| **サブスクリプション（全機種）** | `hasActiveSubscription == true` ですべての機種がアンロック |
| **無料機種（iPhone 4）** | `CameraModel.isFree == true` で常にアンロック |

### アンロック判定メソッド

```swift
extension PurchaseState {
    /// 指定した機種がアンロック済みかを判定する
    func isModelUnlocked(_ model: CameraModel) -> Bool {
        if model.isFree { return true }
        if hasActiveSubscription { return true }
        return purchasedModelIds.contains(model.id)
    }
}
```

### MVPでの扱い

MVPでは使用しない。iPhone 4は無料機種（`isFree == true`）のため、課金判定が不要。

### Phase 2での用途

- 機種選択画面（S-4）でロック/アンロック表示
- 機種詳細画面（S-5）で購入ボタン表示
- StoreKit 2と連携して購入状態を管理
- UserDefaultsまたはKeychain + サーバーサイドレシート検証で永続化

---

## モデル間の関係図

```
                    CameraModel
                   （機種定義・マスターデータ）
                         │
                         │ has
                         ▼
  CameraState        FilterConfig ◄──── ShakeEffect
  （カメラ状態）     （フィルター設定）    （手ブレパラメータ）
       │                 │                    │
       │                 │                    │
       ▼                 ▼                    ▼
                   CaptureResult
                  （撮影結果データ）
                         │
                         │ Phase 2で変換
                         ▼
                   PhotoMetadata
                  （永続化メタデータ）

  ─── Phase 2 ユーザーデータ ───

  UserPreferences ──────► CameraModel
  （ユーザー設定）         selectedCameraModelId で参照

  PurchaseState ────────► CameraModel
  （課金状態）             purchasedModelIds で参照
```

### マスターデータ vs ユーザーデータの分離

| 種別 | モデル | 特徴 |
|------|--------|------|
| マスターデータ | CameraModel, FilterConfig | アプリに組み込み。全ユーザー共通。コード内で定義 |
| 撮影データ | CameraState, CaptureResult, ShakeEffect | 実行時に生成。一時的（MVPでは永続化しない） |
| ユーザーデータ | UserPreferences, PurchaseState | ユーザーごとに異なる。永続化が必要（Phase 2） |
| 永続化データ | PhotoMetadata | 撮影結果のメタデータ。永続化が必要（Phase 2） |

---

## ファイル配置

### MVP

```
Models/
├── CameraState.swift        # CameraState + CameraPosition + PermissionStatus
├── CaptureResult.swift      # CaptureResult
├── FilterConfig.swift       # FilterConfig + プリセット
├── ShakeEffect.swift        # ShakeEffect + ファクトリメソッド
└── CameraModel.swift        # CameraModel + プリセット（MVP: iPhone 4のみ）
```

### Phase 2 追加

```
Models/
├── PhotoMetadata.swift      # PhotoMetadata（SwiftData対応時に @Model 化）
├── UserPreferences.swift    # UserPreferences（UserDefaultsで永続化）
└── PurchaseState.swift      # PurchaseState（StoreKit 2連携）
```
