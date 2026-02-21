# 実装手順ガイド

## 概要

レトロiPhoneカメラアプリ MVP の実装手順。16機能・81テストケースを依存関係に基づいて6つのPhaseに分け、12件のIssueとしてTDDで実装する。7日間のスケジュールに対応する。

---

## 実装順序

```
Phase 1: 基盤層（Day 1）
    Issue #1 Core定数 ──┬──→ Issue #2 Model層
                        │
Phase 2: Service層（Day 2〜3）
    Issue #3 FilterService ←─┤
    Issue #4 CameraService ←─┤
    Issue #5 PhotoLibraryService ←┘
                        │
Phase 3: 手ブレ + ViewModel（Day 4）
    Issue #6 MotionService ←─┤
    Issue #7 CameraViewModel ←── #3, #4, #5, #6
                        │
Phase 4: UI実装（Day 5）
    Issue #8 スキューモーフィズムUI ←─┤
    Issue #9 シャッター演出 ←─────────┤
    Issue #10 CameraPreview ←── #3, #4
                        │
Phase 5: 画面結合（Day 6）
    Issue #11 CameraScreen統合 + パーミッション ←── #7〜#10
                        │
Phase 6: 仕上げ（Day 7）
    Issue #12 実機テスト・チューニング・App Store準備
```

### Phase間の並行可能性

| Phase | Issue | 並行 | 備考 |
|-------|-------|------|------|
| Phase 2 | #3, #4, #5 | **すべて並行可能** | Service間に依存関係なし |
| Phase 3 | #6, #7 | **順序推奨** | #7（ViewModel）は#6（MotionService）に依存 |
| Phase 4 | #8, #9, #10 | **#8, #9は並行可能** | #10は#3, #4に依存 |

---

## Phase 1: 基盤層（Day 1）

### 実装順序

```
#1 → #2（順序必須）
```

### Issue #1: Core定数の実装

**前提:** なし

**ファイル:**
- `Core/Constants/FilterParameters.swift`
- `Core/Constants/CameraConfig.swift`
- `Core/Constants/UIConstants.swift`
- `OldIPhoneCameraExperienceTests/Core/Constants/FilterParametersTests.swift`
- `OldIPhoneCameraExperienceTests/Core/Constants/CameraConfigTests.swift`
- `OldIPhoneCameraExperienceTests/Core/Constants/UIConstantsTests.swift`

**作業内容:**
1. テストファイル作成: テストケース C-FP1〜C-FP3, C-CC1〜C-CC2, C-UI1〜C-UI2 を実装（Red）
2. FilterParameters enum 実装 — フィルターパラメータ定数（Green）
3. CameraConfig enum 実装 — カメラ設定定数（Green）
4. UIConstants enum 実装 — UI関連定数（Green）
5. リファクタリング（Refactor）
6. PR作成

**テストケース（7件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| C-FP1 | warmthShiftが正の値であること（暖色方向） | `> 0` |
| C-FP2 | cropRatioが0〜1の範囲であること | `0 < cropRatio < 1` |
| C-FP3 | shakeShiftRangeの下限が上限より小さいこと | `lowerBound < upperBound` |
| C-CC1 | defaultPositionが背面カメラであること | `.back` |
| C-CC2 | targetFPSが30以上であること | `>= 30` |
| C-UI1 | shutterButtonSizeが正の値であること | `> 0` |
| C-UI2 | irisCloseDurationがirisOpenDurationより短いこと | `close < open` |

**Phase 2拡張ポイント:**
- FilterParameters に機種別の定数セクションを追加可能な構造にする
- `enum FilterParameters` ではなく、将来的に `FilterParameters.iPhone4.warmthShift` のように機種別にアクセスできる名前空間を意識する

**完了確認:**
```bash
make test
```

---

### Issue #2: Model層の実装

**前提:** #1 完了後

**ファイル:**
- `Models/CameraState.swift` — CameraState + CameraPosition + PermissionStatus
- `Models/FilterConfig.swift` — FilterConfig + iPhone 4プリセット
- `Models/ShakeEffect.swift` — ShakeEffect + generateファクトリメソッド
- `Models/CaptureResult.swift` — CaptureResult
- `Models/CameraModel.swift` — CameraModel + iPhone 4プリセット
- `OldIPhoneCameraExperienceTests/Models/CameraStateTests.swift`
- `OldIPhoneCameraExperienceTests/Models/FilterConfigTests.swift`
- `OldIPhoneCameraExperienceTests/Models/ShakeEffectTests.swift`
- `OldIPhoneCameraExperienceTests/Models/CaptureResultTests.swift`
- `OldIPhoneCameraExperienceTests/Models/CameraModelTests.swift`

**作業内容:**
1. テストファイル作成: テストケース M-CS1〜M-CS5, M-FC1〜M-FC5, M-SE1〜M-SE5, M-CR1〜M-CR3, M-CM1〜M-CM3 を実装（Red）
2. CameraState struct + CameraPosition / PermissionStatus enum 実装（Green）
3. FilterConfig struct + `static let iPhone4` プリセット実装（Green）
4. ShakeEffect struct + `static func generate(from:)` 実装（Green）
5. CaptureResult struct 実装（Green）
6. CameraModel struct + `static let iPhone4` プリセット実装（Green）
7. リファクタリング（Refactor）
8. PR作成

**テストケース（21件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-CS1 | デフォルト値でCameraStateを生成する | `isFlashOn == false`, `cameraPosition == .back`, etc. |
| M-CS2 | フラッシュオンの状態を生成する | `isFlashOn == true` |
| M-CS3 | 前面カメラの状態を生成する | `cameraPosition == .front` |
| M-CS4 | CameraPositionのcase数が2であること | `.front`, `.back` |
| M-CS5 | PermissionStatusのcase数が3であること | `.notDetermined`, `.authorized`, `.denied` |
| M-FC1 | iPhone 4プリセットの色温度が暖色方向であること | `warmth > 0` |
| M-FC2 | iPhone 4プリセットの彩度が標準より低いこと | `0 < saturation < 1.0` |
| M-FC3 | iPhone 4プリセットの出力解像度が5MP相当であること | `2592 x 1936` |
| M-FC4 | iPhone 4プリセットのクロップ率が0〜1の範囲であること | `0 < cropRatio < 1` |
| M-FC5 | iPhone 4プリセットのアスペクト比が4:3であること | `width / height ≈ 4/3` |
| M-SE1 | 任意の値でShakeEffectを生成できること | 全プロパティが設定される |
| M-SE2 | generateメソッドでShakeEffectが生成されること | nilでない |
| M-SE3 | shiftX/shiftYが範囲内であること | `1...5` |
| M-SE4 | rotationが範囲内であること | `-0.5...0.5` |
| M-SE5 | motionBlurRadiusが範囲内であること | `1.0...3.0` |
| M-CR1 | 全プロパティを指定して生成できること | 全プロパティが指定値 |
| M-CR2 | shakeEffectがnilの生成ができること | `shakeEffect == nil` |
| M-CR3 | capturedAtが現在時刻に近い値であること | 差が1秒以内 |
| M-CM1 | iPhone 4プリセットのnameが正しいこと | `"iPhone 4"` |
| M-CM2 | iPhone 4プリセットがisFree == trueであること | `true` |
| M-CM3 | iPhone 4のfilterConfigがFilterConfig.iPhone4と一致すること | 各プロパティ一致 |

**設計上の注意:**
- すべて `struct`（イミュータブル）で実装する
- `CameraModel` は MVP では iPhone 4 固定だが、`static let allModels: [CameraModel]` を定義して Phase 2 の機種追加に備える
- `CameraModel.isPurchased` は持たせない（購入状態は `PurchaseState`（Phase 2）で管理）

**完了確認:**
```bash
make test
```

---

## Phase 2: Service層（Day 2〜3）

### 実装順序

```
#3, #4, #5（すべて並行可能）
```

### Issue #3: FilterService — 暖色系色味 + 画角クロップ（F2.1, F2.2）

**前提:** #1, #2 完了後

**ファイル:**
- `Services/FilterService.swift` — FilterServiceProtocol + FilterService
- `OldIPhoneCameraExperienceTests/Services/FilterServiceTests.swift`

**作業内容:**
1. FilterServiceProtocol を定義する（テスタビリティ・DI用）
2. テストファイル作成: テストケース S-F1〜S-F6 を実装（Red）
3. `applyWarmthFilter(_:config:)` 実装 — CITemperatureAndTint + CIColorMatrix（Green）
4. `applyCrop(_:config:)` 実装 — CIImage.cropped + CILanczosScaleTransform（Green）
5. `applyFilters(_:config:)` 統合メソッド実装 — warmth → crop のチェーン（Green）
6. リファクタリング: CIFilterチェーンの最適化（Refactor）
7. PR作成

**テストケース（6件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-F1 | applyWarmthFilterにCIImageを渡すとnilでない結果が返る | nilでない |
| S-F2 | applyWarmthFilter適用後の画像サイズが入力と同じ | extentが一致 |
| S-F3 | FilterConfig.iPhone4のパラメータで正常動作 | エラーなく完了 |
| S-F4 | applyCropでクロップされた画像が返る | 出力 < 入力 |
| S-F5 | 出力画像のアスペクト比が4:3 | width/height ≈ 4/3 |
| S-F6 | 出力画像の解像度が2592x1936 | extent一致 |

**Phase 2拡張ポイント:**
- `applyFilters(_:config:)` は `FilterConfig` をパラメータとして受け取る設計にし、機種ごとに異なるフィルターを適用可能にする
- Phase 2 で追加予定の「低解像度ぼんやり感」「デジタルノイズ」「強コントラスト」は、`FilterService` にメソッドを追加する形で拡張する

**完了確認:**
```bash
make test
```

---

### Issue #4: CameraService — カメラ制御基盤（F1.1, F1.2, F1.3, F1.4）

**前提:** #1, #2 完了後

**ファイル:**
- `Services/CameraService.swift` — CameraServiceProtocol + CameraService
- `OldIPhoneCameraExperienceTests/Services/CameraServiceTests.swift`

**作業内容:**
1. CameraServiceProtocol を定義する
2. テストファイル作成: テストケース S-C1〜S-C6 を実装（Red）
3. AVCaptureSession セットアップ実装 — startSession / stopSession（Green）
4. フラッシュ制御実装 — setFlash(enabled:)（Green）
5. カメラ切り替え実装 — switchCamera()（Green）
6. 写真キャプチャ実装 — capturePhoto() async throws -> CIImage（Green）
7. AVCaptureVideoDataOutputDelegate 実装 — リアルタイムフレーム取得（Green）
8. リファクタリング（Refactor）
9. PR作成

**テストケース（6件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-C1 | startSessionでセッション開始 | `isSessionRunning == true` |
| S-C2 | stopSessionでセッション停止 | `isSessionRunning == false` |
| S-C3 | setFlash(enabled: true)でフラッシュ設定 | `.on` |
| S-C4 | setFlash(enabled: false)でオフ | `.off` |
| S-C5 | switchCameraでカメラ位置切替 | `.back` ↔ `.front` |
| S-C6 | capturePhotoでCIImageが返される | nilでない |

**設計上の注意:**
- AVCaptureVideoDataOutput を使い、フレームごとに CIImage を取得する（FilterService でリアルタイムフィルター適用するため）
- AVCapturePhotoOutput も併用し、高品質な写真キャプチャに使用する
- `async/await` でラップし、コールバック地獄を防ぐ
- テストではモック（MockCameraService）を使用。AVFoundation の実デバイス依存部分はシミュレータでは実行できないため、Protocol ベースの DI が重要

**完了確認:**
```bash
make test
```

---

### Issue #5: PhotoLibraryService — 写真保存・権限管理（F1.2, F3.5, F5.1）

**前提:** #1, #2 完了後

**ファイル:**
- `Services/PhotoLibraryService.swift` — PhotoLibraryServiceProtocol + PhotoLibraryService
- `OldIPhoneCameraExperienceTests/Services/PhotoLibraryServiceTests.swift`

**作業内容:**
1. PhotoLibraryServiceProtocol を定義する
2. テストファイル作成: テストケース S-PL1〜S-PL5 を実装（Red）
3. 権限チェック・リクエスト実装 — checkPermission / requestPermission（Green）
4. 写真保存実装 — saveToPhotoLibrary(_:) async throws（Green）
5. 最新写真取得実装 — fetchLatestPhoto() async -> UIImage?（Green）
6. リファクタリング（Refactor）
7. PR作成

**テストケース（5件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-PL1 | saveToPhotoLibraryにUIImageを渡すと正常完了 | エラーなし |
| S-PL2 | 権限許可済み時checkPermissionがauthorized | `.authorized` |
| S-PL3 | 権限拒否時checkPermissionがdenied | `.denied` |
| S-PL4 | requestPermissionで権限リクエスト実行 | リクエスト実行 |
| S-PL5 | fetchLatestPhotoがサムネイルを返す | nilでない |

**設計上の注意:**
- Info.plist に以下の Purpose String を設定する
  - `NSCameraUsageDescription`: 「iPhone 4風のレトロな写真を撮影するためにカメラを使用します」
  - `NSPhotoLibraryAddUsageDescription`: 「撮影した写真をカメラロールに保存します」
- 写真保存は PHPhotoLibrary.shared().performChanges を使用
- 最新写真取得は PHAsset.fetchAssets + PHImageManager で実装

**完了確認:**
```bash
make test
```

---

## Phase 3: 手ブレ + ViewModel（Day 4）

### 実装順序

```
#6 → #7（順序必須。#7は#3〜#6すべてに依存）
```

### Issue #6: MotionService — ジャイロスコープ + 手ブレシミュレーション（F2.3）

**前提:** #1, #2 完了後

**ファイル:**
- `Services/MotionService.swift` — MotionServiceProtocol + MotionService
- `OldIPhoneCameraExperienceTests/Services/MotionServiceTests.swift`
- `OldIPhoneCameraExperienceTests/Services/FilterServiceTests.swift`（S-F7, S-F8 追加）

**作業内容:**
1. MotionServiceProtocol を定義する
2. テストファイル作成: テストケース S-M1〜S-M4, S-F7〜S-F8 を実装（Red）
3. CMMotionManager セットアップ — startUpdates / stopUpdates（Green）
4. getCurrentMotion 実装 — 現在のデバイスモーション取得（Green）
5. generateShakeEffect 実装 — ジャイロデータ → ShakeEffect 変換（Green）
6. FilterService に `applyShakeEffect(_:effect:)` メソッド追加（Green）
7. FilterService の `applyAllFilters(_:config:shakeEffect:)` 統合メソッドに手ブレを追加（Green）
8. リファクタリング（Refactor）
9. PR作成

**テストケース（6件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-M1 | startUpdatesでジャイロ更新開始 | `isUpdating == true` |
| S-M2 | stopUpdatesでジャイロ更新停止 | `isUpdating == false` |
| S-M3 | getCurrentMotionがCMDeviceMotion?を返す | 型が正しい |
| S-M4 | generateShakeEffectがShakeEffectを返す | nilでない |
| S-F7 | applyShakeEffectにCIImageとShakeEffectを渡すとnilでない結果 | nilでない |
| S-F8 | 2回applyShakeEffectを呼ぶと異なる結果（ランダム性） | 完全一致しない |

**スケジュールリスク時の対応:**
- 開発が遅延した場合、Issue #6 全体を Phase 2（MVPリリース後）に回す
- その場合、CameraViewModel（Issue #7）で `shakeEffect: nil` をハードコードする

**完了確認:**
```bash
make test
```

---

### Issue #7: CameraViewModel — 全Service結合（F1.1〜F1.4, F2.1〜F2.3, F5.1）

**前提:** #3, #4, #5, #6 完了後

**ファイル:**
- `ViewModels/CameraViewModel.swift`
- `OldIPhoneCameraExperienceTests/ViewModels/CameraViewModelTests.swift`
- `OldIPhoneCameraExperienceTests/Mocks/` — 各Serviceのモック

**作業内容:**
1. テストファイル作成: テストケース VM-C1〜VM-C14 を実装（Red）
2. 各Serviceのモック作成: MockCameraService, MockFilterService, MockPhotoLibraryService, MockMotionService
3. CameraViewModel の `@Observable final class` 骨格実装（Green）
4. 初期状態の実装 — isFlashOn, isFrontCamera, isCapturing, lastCapturedImage, permissionDenied（Green）
5. toggleFlash() 実装 — フラッシュ切り替え + CameraService.setFlash 呼び出し（Green）
6. toggleCamera() 実装 — カメラ切り替え + フラッシュリセット + CameraService.switchCamera 呼び出し（Green）
7. capturePhoto() 実装 — 撮影 → フィルター適用（暖色+クロップ+手ブレ）→ 保存 → サムネイル更新（Green）
8. パーミッション管理実装 — checkCameraPermission, requestPermission（Green）
9. リファクタリング: Service呼び出しの整理（Refactor）
10. PR作成

**テストケース（14件）:**

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C1 | 初期状態でフラッシュがオフ | `isFlashOn == false` |
| VM-C2 | 初期状態で背面カメラ | `isFrontCamera == false` |
| VM-C3 | 初期状態で撮影中でない | `isCapturing == false` |
| VM-C4 | 初期状態でlastCapturedImageがnil | `nil` |
| VM-C5 | toggleFlashでフラッシュ状態反転 | `false → true` |
| VM-C6 | toggleFlashを2回呼ぶと元に戻る | `false → true → false` |
| VM-C7 | toggleFlash時にCameraService.setFlashが呼ばれる | `setFlashCalled == true` |
| VM-C8 | toggleCameraでカメラ位置反転 | `false → true` |
| VM-C9 | 前面カメラ切り替え時にフラッシュオフ | `isFlashOn == false` |
| VM-C10 | toggleCamera時にCameraService.switchCameraが呼ばれる | `switchCameraCalled == true` |
| VM-C11 | capturePhoto中にisCapturingがtrue | 処理中 `true` |
| VM-C12 | capturePhoto完了後にisCapturingがfalse | `false` |
| VM-C13 | capturePhoto完了後にlastCapturedImage更新 | nilでない |
| VM-C14 | カメラ権限拒否時にpermissionDeniedがtrue | `true` |

**設計上の注意:**
- `@MainActor` を付けてメインスレッドでの状態更新を保証する
- 撮影パイプライン: CameraService.capturePhoto() → FilterService.applyAllFilters() → PhotoLibraryService.save() → fetchLatestPhoto()
- MVP では `let currentModel: CameraModel = .iPhone4` を固定。Phase 2 で動的に切り替え可能にする
- すべてのServiceはProtocol経由でイニシャライザ注入する（テスト時にモック差し替え）

**完了確認:**
```bash
make test
```

---

## Phase 4: UI実装（Day 5）

### 実装順序

```
#8, #9（並行可能）
#10 ←── #3, #4 に依存
```

### Issue #8: スキューモーフィズムUIコンポーネント（F3.1〜F3.5）

**前提:** #2 完了後（Modelの型定義を参照するため）

**ファイル:**
- `Views/Components/Skeuomorphic/TopToolbar.swift` — F3.1
- `Views/Components/Skeuomorphic/ShutterButton.swift` — F3.3
- `Views/Components/Skeuomorphic/BottomToolbar.swift` — F3.4
- `Views/Components/Camera/PhotoThumbnail.swift` — F3.5
- `OldIPhoneCameraExperienceTests/Views/Components/TopToolbarTests.swift`
- `OldIPhoneCameraExperienceTests/Views/Components/BottomToolbarTests.swift`
- `OldIPhoneCameraExperienceTests/Views/Components/ShutterButtonTests.swift`

**作業内容:**
1. テストファイル作成: テストケース V-TB1〜V-TB4, V-BT1〜V-BT3, V-SB1〜V-SB3 を実装（Red）
2. swift-snapshot-testing パッケージを追加する
3. TopToolbar 実装 — LinearGradient背景 + フラッシュボタン + カメラ切替ボタン + ベベル/シャドウ（Green）
4. ShutterButton 実装 — Circle + RadialGradient + 金属質感 + 押し込みアニメーション + 無効化状態（Green）
5. BottomToolbar 実装 — 黒背景 + 金属テクスチャ + シャッターボタン配置 + サムネイル配置（Green）
6. PhotoThumbnail 実装 — サムネイル表示 + 空枠 + タップでカメラロール遷移（Green）
7. 各コンポーネントの Xcode Preview 作成
8. リファクタリング: スキューモーフィズムのデザイン統一（Refactor）
9. PR作成

**テストケース（10件）:**

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-TB1 | 背面カメラ・フラッシュオフ状態 | フラッシュボタン表示、非ハイライト | スナップショット |
| V-TB2 | 前面カメラ状態 | フラッシュボタン非表示 | スナップショット |
| V-TB3 | フラッシュボタンタップ | onFlashToggle発火 | インタラクション |
| V-TB4 | カメラ切替ボタンタップ | onCameraToggle発火 | インタラクション |
| V-BT1 | サムネイルなし状態 | 空枠表示 | スナップショット |
| V-BT2 | サムネイルあり状態 | サムネイル表示 | スナップショット |
| V-BT3 | サムネイルタップ | onThumbnailTap発火 | インタラクション |
| V-SB1 | 通常状態 | 金属質感ボタン表示 | スナップショット |
| V-SB2 | 撮影中（無効化）状態 | グレーアウト表示 | スナップショット |
| V-SB3 | ボタンタップ | onShutter発火 | インタラクション |

**UIデザインの指針:**
- すべてのUI部品はSwiftUIのカスタム描画（Shape, Canvas, LinearGradient, RadialGradient, shadow）で実装する
- 画像アセットへの依存は最小限にする
- screens.md の S-1 レイアウトに準拠する
- 各コンポーネントは ViewModel に依存せず、プロパティ・クロージャで受け取る設計にする（再利用性・Preview対応）

**完了確認:**
```bash
make test
```

---

### Issue #9: シャッター演出（F4.1, F4.2, F4.3）

**前提:** #2 完了後

**ファイル:**
- `Views/Components/Skeuomorphic/IrisShutter.swift` — F4.1 虹彩絞りアニメーション
- `Resources/Sounds/shutter.caf` — F4.2 シャッター音SE
- `Services/SoundService.swift` — シャッター音再生（消音モード対応）
- `OldIPhoneCameraExperienceTests/Views/Components/IrisShutterTests.swift`

**作業内容:**
1. テストファイル作成: テストケース V-IS1〜V-IS2 を実装（Red）
2. IrisShutter 実装 — 6〜8枚の絞り羽根を Path で描画 + 開閉アニメーション（Green）
3. SoundService 実装 — AudioServicesPlaySystemSound で消音モードを無視して再生（Green）
4. シャッター音SEファイルを Resources/Sounds/ に配置（オリジナルまたはフリー素材）
5. 白フェード演出 — Color.white オーバーレイ + opacity アニメーション（CameraScreen内で実装）
6. リファクタリング: アニメーションタイミングの調整（Refactor）
7. PR作成

**テストケース（2件）:**

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-IS1 | 開いた状態（非表示）のスナップショット | 絞り羽根が完全に開いている | スナップショット |
| V-IS2 | 閉じた状態のスナップショット | 絞り羽根が中心に閉じている | スナップショット |

**アニメーションタイミング（UIConstants参照）:**

| 演出 | 時間 | 実装 |
|------|------|------|
| 虹彩絞り（閉じる） | 約0.2秒 | withAnimation(.easeIn) |
| 虹彩絞り（開く） | 約0.3秒 | withAnimation(.easeOut) |
| 白フェード | 約0.15秒 | withAnimation(.linear) |

**シャッター音の注意:**
- **消音モードに関係なく常に鳴らす**（日本市場向け要件）
- AudioServicesPlaySystemSound または AVAudioSession.category = .playback で実現
- シャッター音SEは著作権に配慮し、オリジナルまたはフリー素材を使用する

**完了確認:**
```bash
make test
```

---

### Issue #10: CameraPreview — リアルタイムフィルタープレビュー（F3.2, F1.1）

**前提:** #3（FilterService）, #4（CameraService） 完了後

**ファイル:**
- `Views/Components/Camera/CameraPreview.swift` — UIViewRepresentable

**作業内容:**
1. CameraPreview（UIViewRepresentable）を実装 — AVCaptureVideoDataOutput のフレームにフィルターを適用してリアルタイム表示
2. Metal/Core Image レンダリング — CIImage → MTKView or CALayer で描画
3. 4:3 アスペクト比の制約を実装
4. パフォーマンス最適化 — 30fps 以上を確保
5. Xcode Preview 作成（モックフレームを使用）
6. PR作成

**テストケース:** なし（UIViewRepresentable はスナップショットテスト対象外。実機での目視確認）

**パフォーマンス目標（非機能要件）:**
- プレビューFPS: 30fps以上
- フィルター処理がフレームドロップを起こさないこと
- プレビュー解像度は表示解像度に合わせて最適化（フル解像度での処理は不要）

**技術的な選択肢:**
- **方式A（推奨）:** AVCaptureVideoDataOutput → CIFilter適用 → MTKView で Metal レンダリング
- **方式B:** AVCaptureVideoDataOutput → CIFilter適用 → CIContext.render → CALayer.contents

**完了確認:**
```bash
make build
```
※ 実機でプレビューが30fps以上で表示されることを目視確認

---

## Phase 5: 画面結合（Day 6）

### Issue #11: CameraScreen統合 + パーミッション管理（S-1〜S-3, F5.1）

**前提:** #7（CameraViewModel）, #8, #9, #10 完了後

**ファイル:**
- `Views/Screens/CameraScreen.swift` — メイン画面
- `Views/Screens/PermissionDeniedView.swift` — 権限拒否表示
- `OldIPhoneCameraExperienceTests/Views/Screens/CameraScreenTests.swift`
- `OldIPhoneCameraExperienceApp.swift` — エントリーポイント更新

**作業内容:**
1. テストファイル作成: テストケース V-CS1〜V-CS4 を実装（Red）
2. CameraScreen 実装 — TopToolbar + CameraPreview + BottomToolbar を VStack で結合（Green）
3. CameraViewModel との接続 — @State で保持、各コンポーネントにプロパティ・クロージャを渡す（Green）
4. 撮影フロー統合 — シャッターボタン → 虹彩絞り → 白フェード → capturePhoto → シャッター音（Green）
5. パーミッション管理実装 — 起動時の権限チェック → ダイアログ表示 or 拒否画面表示（Green）
6. PermissionDeniedView 実装 — S-3a, S-3c のUI（Green）
7. 状態バリエーション確認 — S-1a〜S-1e, S-3a〜S-3c がすべて正しく表示されること（Green）
8. ステータスバー非表示設定 — `.prefersStatusBarHidden(true)` / `.persistentSystemOverlays(.hidden)`
9. ポートレート固定設定 — Info.plist の UISupportedInterfaceOrientations
10. リファクタリング（Refactor）
11. PR作成

**テストケース（4件）:**

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-CS1 | 通常状態（S-1a）のスナップショット | ツールバー・ファインダー・ボトムバー正常配置 | スナップショット |
| V-CS2 | 前面カメラ状態（S-1b）のスナップショット | フラッシュボタン非表示 | スナップショット |
| V-CS3 | カメラ権限拒否状態（S-3a）のスナップショット | 権限拒否メッセージ + 「設定を開く」ボタン | スナップショット |
| V-CS4 | ステータスバーが非表示であること | システムステータスバーなし | スナップショット |

**統合チェックリスト:**
- [ ] 撮影フロー: シャッターボタン → 虹彩絞り閉 → 白フェード → 撮影処理 → 虹彩絞り開 → サムネイル更新
- [ ] フラッシュ: トグル動作、前面カメラ時非表示
- [ ] カメラ切替: フリップアニメーション、フラッシュリセット
- [ ] パーミッション: 未決定 → ダイアログ、拒否 → S-3a表示、許可 → S-1表示
- [ ] ステータスバー非表示
- [ ] ポートレート固定
- [ ] サムネイルタップ → カメラロール遷移

**完了確認:**
```bash
make check
```

---

## Phase 6: 仕上げ（Day 7）

### Issue #12: 実機テスト・フィルターチューニング・App Store準備

**前提:** #11 完了後

**ファイル:** 変更対象は状況に応じて決定

**作業内容:**

#### 1. 実機テスト

| テスト項目 | 確認内容 |
|-----------|---------|
| プレビューFPS | 30fps以上（iPhone 12〜最新機種で確認） |
| 撮影〜保存 | 1秒以内 |
| アプリ起動〜撮影可能 | 2秒以内 |
| シャッター音 | 消音モードでも鳴る |
| フラッシュ | 背面カメラで発光する |
| カメラ切替 | スムーズに切り替わる |
| パーミッション | 許可/拒否/設定変更後のフロー |

#### 2. フィルターチューニング

実際のiPhone 4で撮影した写真と並べて比較し、以下のパラメータを調整する:

| パラメータ | 調整対象 | 目標 |
|-----------|---------|------|
| warmth | 色温度シフト量 | iPhone 4の暖色感に近づける |
| saturation | 彩度 | 素朴なくすみ感を出す |
| highlightTintIntensity | ハイライトティント | 黄〜オレンジの自然なティント |
| cropRatio | クロップ率 | 32mm相当の画角 |
| shakeShiftRange | 手ブレ量 | 自然な微ブレ（やりすぎない） |
| motionBlurRadiusRange | モーションブラー量 | 控えめなブラー |

#### 3. App Store準備

- [ ] アプリアイコン作成（iOS 6時代のカメラアイコン風）
- [ ] スクリーンショット撮影（6.7インチ、6.1インチ）
- [ ] App Store説明文（日本語）
- [ ] プライバシーポリシーURL
- [ ] サポートURL
- [ ] バージョン番号設定（1.0.0）
- [ ] `bundle exec fastlane release` で App Store 提出

**完了確認:**
```bash
make ci
bundle exec fastlane release
```

---

## テストケースサマリー

| Phase | Issue | テスト数 | テストID |
|-------|-------|---------|---------|
| Phase 1 | #1 Core定数 | 7 | C-FP1〜3, C-CC1〜2, C-UI1〜2 |
| Phase 1 | #2 Model層 | 21 | M-CS1〜5, M-FC1〜5, M-SE1〜5, M-CR1〜3, M-CM1〜3 |
| Phase 2 | #3 FilterService | 6 | S-F1〜6 |
| Phase 2 | #4 CameraService | 6 | S-C1〜6 |
| Phase 2 | #5 PhotoLibraryService | 5 | S-PL1〜5 |
| Phase 3 | #6 MotionService | 6 | S-M1〜4, S-F7〜8 |
| Phase 3 | #7 CameraViewModel | 14 | VM-C1〜14 |
| Phase 4 | #8 スキューモーフィズムUI | 10 | V-TB1〜4, V-BT1〜3, V-SB1〜3 |
| Phase 4 | #9 シャッター演出 | 2 | V-IS1〜2 |
| Phase 4 | #10 CameraPreview | 0 | （実機目視確認） |
| Phase 5 | #11 CameraScreen統合 | 4 | V-CS1〜4 |
| Phase 6 | #12 仕上げ | 0 | （手動テスト） |
| **合計** | **12 Issue** | **81** | |

---

## 各Issue共通チェックリスト

- [ ] テストコード作成（TDD: Red）
- [ ] 実装（TDD: Green）
- [ ] リファクタリング（TDD: Refactor）
- [ ] `make lint` — SwiftLint 0警告
- [ ] `make test` — 全テスト通過
- [ ] `make build` — ビルド成功
- [ ] PR作成（git-rules.md + self-review-checklist.md に準拠）

---

## スケジュール対応表

| Day | Phase | Issue | 主な成果物 |
|-----|-------|-------|-----------|
| Day 1 | Phase 1 | #1, #2 | Core定数・5つのModel完成、28テスト通過 |
| Day 2 | Phase 2 | #3 | FilterService（暖色+クロップ）完成、6テスト通過 |
| Day 3 | Phase 2 | #4, #5 | CameraService + PhotoLibraryService完成、11テスト通過 |
| Day 4 | Phase 3 | #6, #7 | MotionService + CameraViewModel完成、20テスト通過 |
| Day 5 | Phase 4 | #8, #9, #10 | 全UIコンポーネント + CameraPreview完成、12テスト通過 |
| Day 6 | Phase 5 | #11 | CameraScreen統合 + パーミッション、4テスト通過。全81テスト通過 |
| Day 7 | Phase 6 | #12 | 実機テスト・チューニング・App Store提出 |

---

## 参照ドキュメント

| ドキュメント | 用途 |
|-------------|------|
| [docs/features.md](features.md) | 16機能の詳細仕様・受け入れ条件・優先順位 |
| [docs/test-cases.md](test-cases.md) | 81テストケースの定義（TDD Red Phase用） |
| [docs/data-model.md](data-model.md) | 8つのデータモデル定義 |
| [docs/architecture.md](architecture.md) | MVVM構成・レイヤー責務・DI方針 |
| [docs/screens.md](screens.md) | 画面レイアウト・状態バリエーション |
| [docs/mvp-requirements.md](mvp-requirements.md) | 非機能要件・スケジュール |
| [docs/human-interface-guideline.md](human-interface-guideline.md) | UIデザイン判断基準 |
| [docs/self-review-checklist.md](self-review-checklist.md) | PR作成前チェック |
| [docs/git-rules.md](git-rules.md) | ブランチ・コミット規則 |
| [CLAUDE.md](../CLAUDE.md) | TDDワークフロー・実装ルール |
