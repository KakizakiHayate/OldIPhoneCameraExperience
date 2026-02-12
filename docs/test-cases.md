# テストケース一覧

本ドキュメントはMVP（Phase 1）の全テストケースを定義する。
TDD（Red → Green → Refactor）の Red Phase で、このテストケースに基づいてテストコードを作成する。

---

## テストケースID命名規則

```
[レイヤー略称]-[対象略称][連番]
```

| レイヤー略称 | 対象 | 例 |
|-------------|------|-----|
| M | Model | M-CS1（CameraState テスト #1） |
| VM | ViewModel | VM-C1（CameraViewModel テスト #1） |
| S | Service | S-F1（FilterService テスト #1） |
| C | Core/Constants | C-FP1（FilterParameters テスト #1） |
| V | View | V-TB1（TopToolbar テスト #1） |

---

## テストケースサマリー

| レイヤー | テスト対象 | ケース数 | テストファイル |
|---------|-----------|---------|---------------|
| Model | CameraState | 5 | `Tests/Models/CameraStateTests.swift` |
| Model | FilterConfig | 5 | `Tests/Models/FilterConfigTests.swift` |
| Model | ShakeEffect | 5 | `Tests/Models/ShakeEffectTests.swift` |
| Model | CaptureResult | 3 | `Tests/Models/CaptureResultTests.swift` |
| Model | CameraModel | 3 | `Tests/Models/CameraModelTests.swift` |
| ViewModel | CameraViewModel | 14 | `Tests/ViewModels/CameraViewModelTests.swift` |
| Service | FilterService | 8 | `Tests/Services/FilterServiceTests.swift` |
| Service | CameraService | 6 | `Tests/Services/CameraServiceTests.swift` |
| Service | PhotoLibraryService | 5 | `Tests/Services/PhotoLibraryServiceTests.swift` |
| Service | MotionService | 4 | `Tests/Services/MotionServiceTests.swift` |
| Core | FilterParameters | 3 | `Tests/Core/Constants/FilterParametersTests.swift` |
| Core | CameraConfig | 2 | `Tests/Core/Constants/CameraConfigTests.swift` |
| Core | UIConstants | 2 | `Tests/Core/Constants/UIConstantsTests.swift` |
| View | TopToolbar | 4 | `Tests/Views/Components/TopToolbarTests.swift` |
| View | BottomToolbar | 3 | `Tests/Views/Components/BottomToolbarTests.swift` |
| View | ShutterButton | 3 | `Tests/Views/Components/ShutterButtonTests.swift` |
| View | IrisShutter | 2 | `Tests/Views/Components/IrisShutterTests.swift` |
| View | CameraScreen | 4 | `Tests/Views/Screens/CameraScreenTests.swift` |
| **合計** | | **81** | |

---

## Model テスト

### CameraState（5ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-CS1 | デフォルト値でCameraStateを生成する | `isFlashOn == false`, `cameraPosition == .back`, `isCapturing == false`, `permissionStatus == .notDetermined` |
| M-CS2 | フラッシュオンの状態を生成する | `isFlashOn == true` |
| M-CS3 | 前面カメラの状態を生成する | `cameraPosition == .front` |
| M-CS4 | CameraPositionのcase数が2であること | `.front`, `.back` の2ケースのみ |
| M-CS5 | PermissionStatusのcase数が3であること | `.notDetermined`, `.authorized`, `.denied` の3ケースのみ |

### FilterConfig（5ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-FC1 | iPhone 4プリセットの色温度が暖色方向であること | `FilterConfig.iPhone4.warmth > 0`（正の値 = 暖色シフト） |
| M-FC2 | iPhone 4プリセットの彩度が標準より低いこと | `FilterConfig.iPhone4.saturation < 1.0` かつ `> 0.0` |
| M-FC3 | iPhone 4プリセットの出力解像度が5MP相当であること | `outputWidth == 2592`, `outputHeight == 1936` |
| M-FC4 | iPhone 4プリセットのクロップ率が0〜1の範囲であること | `cropRatio > 0.0` かつ `cropRatio < 1.0` |
| M-FC5 | iPhone 4プリセットのアスペクト比が4:3であること | `outputWidth / outputHeight` が `4.0 / 3.0` に近似 |

### ShakeEffect（5ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-SE1 | 任意の値でShakeEffectを生成できること | 全プロパティに指定値が設定される |
| M-SE2 | generateメソッドでShakeEffectが生成されること | nilでないShakeEffectが返される |
| M-SE3 | generateメソッドのshiftX/shiftYが範囲内であること | `1...5` の範囲内 |
| M-SE4 | generateメソッドのrotationが範囲内であること | `-0.5...0.5` の範囲内 |
| M-SE5 | generateメソッドのmotionBlurRadiusが範囲内であること | `1.0...3.0` の範囲内 |

### CaptureResult（3ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-CR1 | 全プロパティを指定してCaptureResultを生成できること | 全プロパティが指定値で設定される |
| M-CR2 | shakeEffectがnilのCaptureResultを生成できること | `shakeEffect == nil` |
| M-CR3 | capturedAtが現在時刻に近い値であること | 生成直後の`capturedAt`と`Date()`の差が1秒以内 |

### CameraModel（3ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| M-CM1 | iPhone 4プリセットのnameが"iPhone 4"であること | `CameraModel.iPhone4.name == "iPhone 4"` |
| M-CM2 | iPhone 4プリセットが購入済みであること | `CameraModel.iPhone4.isPurchased == true` |
| M-CM3 | iPhone 4プリセットのfilterConfigがFilterConfig.iPhone4と一致すること | 各プロパティが一致 |

---

## ViewModel テスト

### CameraViewModel（14ケース）

テスト時はService層をモック注入する。

#### 初期状態

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C1 | 初期状態でフラッシュがオフであること | `viewModel.isFlashOn == false` |
| VM-C2 | 初期状態で背面カメラであること | `viewModel.isFrontCamera == false` |
| VM-C3 | 初期状態で撮影中でないこと | `viewModel.isCapturing == false` |
| VM-C4 | 初期状態でlastCapturedImageがnilであること | `viewModel.lastCapturedImage == nil` |

#### フラッシュ切り替え（F1.3）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C5 | toggleFlash呼び出しでフラッシュ状態が反転すること | `isFlashOn` が `false` → `true` に変化 |
| VM-C6 | toggleFlashを2回呼ぶと元に戻ること | `isFlashOn` が `false` → `true` → `false` |
| VM-C7 | toggleFlash呼び出し時にCameraService.setFlashが呼ばれること | `mockCameraService.setFlashCalled == true` |

#### カメラ切り替え（F1.4）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C8 | toggleCamera呼び出しでカメラ位置が反転すること | `isFrontCamera` が `false` → `true` に変化 |
| VM-C9 | 前面カメラに切り替え時、フラッシュがオフになること | `isFlashOn == false`（前面カメラにフラッシュなし） |
| VM-C10 | toggleCamera呼び出し時にCameraService.switchCameraが呼ばれること | `mockCameraService.switchCameraCalled == true` |

#### 撮影（F1.2）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C11 | capturePhoto呼び出しでisCapturingがtrueになること | 処理中に`isCapturing == true` |
| VM-C12 | capturePhoto完了後にisCapturingがfalseに戻ること | 完了後に`isCapturing == false` |
| VM-C13 | capturePhoto完了後にlastCapturedImageが更新されること | `lastCapturedImage != nil` |

#### パーミッション（F5.1）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| VM-C14 | カメラ権限が拒否されている場合、permissionDeniedがtrueになること | `viewModel.permissionDenied == true` |

---

## Service テスト

### FilterService（8ケース）

#### 暖色系フィルター（F2.1）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-F1 | applyWarmthFilterにCIImageを渡すとnilでない結果が返ること | 戻り値が `CIImage?` で `nil` でない |
| S-F2 | applyWarmthFilter適用後の画像サイズが入力と同じであること | 入力と出力の`extent`が一致 |
| S-F3 | FilterConfig.iPhone4のパラメータでフィルターが正常に動作すること | エラーなく処理が完了する |

#### 画角クロップ（F2.2）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-F4 | applyCropにCIImageを渡すとクロップされた画像が返ること | 出力の`extent`が入力より小さい |
| S-F5 | 出力画像のアスペクト比が4:3であること | `width / height` が `4.0 / 3.0` に近似 |
| S-F6 | 出力画像の解像度が2592x1936であること | `extent.width == 2592`, `extent.height == 1936` |

#### 手ブレシミュレーション（F2.3）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-F7 | applyShakeEffectにCIImageとShakeEffectを渡すとnilでない結果が返ること | 戻り値が `nil` でない |
| S-F8 | 2回applyShakeEffectを呼ぶと異なる結果が返ること（ランダム性） | 2回の出力が完全一致しない |

### CameraService（6ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-C1 | startSessionを呼ぶとセッションが開始されること | `isSessionRunning == true` |
| S-C2 | stopSessionを呼ぶとセッションが停止すること | `isSessionRunning == false` |
| S-C3 | setFlash(enabled: true)でフラッシュモードが設定されること | フラッシュモードが`.on`に設定 |
| S-C4 | setFlash(enabled: false)でフラッシュモードがオフになること | フラッシュモードが`.off`に設定 |
| S-C5 | switchCameraを呼ぶとカメラ位置が切り替わること | `.back` → `.front` または逆 |
| S-C6 | capturePhotoを呼ぶとCIImageが返されること | 戻り値が `nil` でない |

### PhotoLibraryService（5ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-PL1 | saveToPhotoLibraryにUIImageを渡すと正常に完了すること | エラーなく完了 |
| S-PL2 | カメラロール権限が許可済みの場合、checkPermissionがauthorizedを返すこと | `.authorized` |
| S-PL3 | カメラロール権限が拒否の場合、checkPermissionがdeniedを返すこと | `.denied` |
| S-PL4 | requestPermissionを呼ぶとシステムの権限ダイアログが表示されること | 権限リクエストが実行される |
| S-PL5 | fetchLatestPhotoが直近保存した写真のサムネイルを返すこと | `UIImage?` が `nil` でない |

### MotionService（4ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| S-M1 | startUpdatesを呼ぶとジャイロスコープの更新が開始されること | `isUpdating == true` |
| S-M2 | stopUpdatesを呼ぶとジャイロスコープの更新が停止すること | `isUpdating == false` |
| S-M3 | getCurrentMotionがCMDeviceMotion?を返すこと | 型が正しい（シミュレータではnil許容） |
| S-M4 | generateShakeEffectがShakeEffectを返すこと | 戻り値が `nil` でない |

---

## Core テスト

### FilterParameters（3ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| C-FP1 | warmthShiftが正の値であること（暖色方向） | `FilterParameters.warmthShift > 0` |
| C-FP2 | cropRatioが0〜1の範囲であること | `0 < cropRatio < 1` |
| C-FP3 | shakeShiftRangeの下限が上限より小さいこと | `lowerBound < upperBound` |

### CameraConfig（2ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| C-CC1 | defaultPositionが背面カメラであること | `.back` |
| C-CC2 | targetFPSが30以上であること | `>= 30` |

### UIConstants（2ケース）

| ID | テストケース | 期待結果 |
|----|-------------|---------|
| C-UI1 | shutterButtonSizeが正の値であること | `> 0` |
| C-UI2 | irisCloseDurationがirisOpenDurationより短いこと | `irisCloseDuration < irisOpenDuration` |

---

## View テスト

SwiftUIのViewテストはスナップショットテスト + インタラクションテストで実施する。

### テスト方式

| 方式 | 用途 | ツール |
|------|------|--------|
| スナップショットテスト | UIの見た目が意図通りかを画像比較で検証 | swift-snapshot-testing |
| インタラクションテスト | ボタンタップ等のユーザー操作でコールバックが呼ばれるかを検証 | ViewInspector or XCTest |

### TopToolbar（4ケース）

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-TB1 | 背面カメラ・フラッシュオフ状態のスナップショット | フラッシュボタン表示、カメラ切替ボタン表示、フラッシュアイコンが非ハイライト | スナップショット |
| V-TB2 | 前面カメラ状態のスナップショット | フラッシュボタン非表示、カメラ切替ボタン表示 | スナップショット |
| V-TB3 | フラッシュボタンタップでonFlashToggleコールバックが呼ばれること | コールバック発火 | インタラクション |
| V-TB4 | カメラ切替ボタンタップでonCameraToggleコールバックが呼ばれること | コールバック発火 | インタラクション |

### BottomToolbar（3ケース）

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-BT1 | サムネイルなし状態のスナップショット | 空枠が表示される、シャッターボタンが中央 | スナップショット |
| V-BT2 | サムネイルあり状態のスナップショット | サムネイル画像が左側に表示される | スナップショット |
| V-BT3 | サムネイルタップでonThumbnailTapコールバックが呼ばれること | コールバック発火 | インタラクション |

### ShutterButton（3ケース）

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-SB1 | 通常状態のスナップショット | 金属質感ボタン、カメラアイコン表示 | スナップショット |
| V-SB2 | 撮影中（無効化）状態のスナップショット | ボタンがグレーアウト/無効化表示 | スナップショット |
| V-SB3 | ボタンタップでonShutterコールバックが呼ばれること | コールバック発火 | インタラクション |

### IrisShutter（2ケース）

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-IS1 | 開いた状態（非表示）のスナップショット | 絞り羽根が完全に開いている（透過） | スナップショット |
| V-IS2 | 閉じた状態のスナップショット | 絞り羽根が中心に閉じている | スナップショット |

### CameraScreen（4ケース）

| ID | テストケース | 期待結果 | 方式 |
|----|-------------|---------|------|
| V-CS1 | 通常状態（S-1a）のスナップショット | トップツールバー、ファインダー、ボトムツールバーが正しく配置 | スナップショット |
| V-CS2 | 前面カメラ状態（S-1b）のスナップショット | フラッシュボタン非表示 | スナップショット |
| V-CS3 | カメラ権限拒否状態（S-3a）のスナップショット | 権限拒否メッセージと「設定を開く」ボタンが表示 | スナップショット |
| V-CS4 | ステータスバーが非表示であること | システムステータスバーが画面に表示されていない | スナップショット |

---

## テストファイル配置

```
OldIPhoneCameraExperienceTests/
├── Models/
│   ├── CameraStateTests.swift          # M-CS1〜M-CS5
│   ├── FilterConfigTests.swift         # M-FC1〜M-FC5
│   ├── ShakeEffectTests.swift          # M-SE1〜M-SE5
│   ├── CaptureResultTests.swift        # M-CR1〜M-CR3
│   └── CameraModelTests.swift          # M-CM1〜M-CM3
├── ViewModels/
│   └── CameraViewModelTests.swift      # VM-C1〜VM-C14
├── Services/
│   ├── FilterServiceTests.swift        # S-F1〜S-F8
│   ├── CameraServiceTests.swift        # S-C1〜S-C6
│   ├── PhotoLibraryServiceTests.swift  # S-PL1〜S-PL5
│   └── MotionServiceTests.swift        # S-M1〜S-M4
├── Core/
│   └── Constants/
│       ├── FilterParametersTests.swift # C-FP1〜C-FP3
│       ├── CameraConfigTests.swift     # C-CC1〜C-CC2
│       └── UIConstantsTests.swift      # C-UI1〜C-UI2
└── Views/
    ├── Components/
    │   ├── TopToolbarTests.swift       # V-TB1〜V-TB4
    │   ├── BottomToolbarTests.swift    # V-BT1〜V-BT3
    │   ├── ShutterButtonTests.swift    # V-SB1〜V-SB3
    │   └── IrisShutterTests.swift      # V-IS1〜V-IS2
    └── Screens/
        └── CameraScreenTests.swift     # V-CS1〜V-CS4
```

---

## テスト実行コマンド

```bash
# 全テスト実行
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16'

# レイヤー別実行（フィルタリング）
# Model テストのみ
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:OldIPhoneCameraExperienceTests/Models

# Service テストのみ
xcodebuild test -scheme OldIPhoneCameraExperience -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:OldIPhoneCameraExperienceTests/Services
```

---

## 参照ドキュメント

| ドキュメント | テストケースでの用途 |
|-------------|-------------------|
| [features.md](features.md) | 機能IDと受け入れ条件の参照 |
| [data-model.md](data-model.md) | Modelのプロパティ・デフォルト値の参照 |
| [screens.md](screens.md) | 画面の状態バリエーション・レイアウトの参照 |
| [architecture.md](architecture.md) | テストファイルの配置ルールの参照 |
