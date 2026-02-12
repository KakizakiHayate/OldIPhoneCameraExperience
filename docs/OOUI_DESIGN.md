# オブジェクト指向UI設計（OOUI Design）

---

## 1. OOUIとは

### 1.1 基本概念

**オブジェクト指向UI（OOUI）** とは、ユーザーが**オブジェクト（名詞）を先に選び、次にアクション（動詞）を選ぶ**というインタラクション順序でUIを設計する手法である。

```
OOUI:         オブジェクト（名詞）→ アクション（動詞）
タスク指向UI:  アクション（動詞）→ オブジェクト（名詞）
```

#### 具体例: 写真アプリ

| 操作 | OOUI | タスク指向UI |
|---|---|---|
| 写真を削除 | 写真一覧 → 写真を選ぶ → 「削除」を選ぶ | メニュー → 「削除」を選ぶ → どの写真か選ぶ |
| 写真を共有 | 写真一覧 → 写真を選ぶ → 「共有」を選ぶ | メニュー → 「共有」を選ぶ → どの写真か選ぶ |

OOUIでは、**同じオブジェクト（写真）に対して複数のアクションが自然に提供される**。タスク指向UIでは、タスクごとに別の画面フローが必要になる。

### 1.2 OOUIの4原則

| 原則 | 説明 |
|---|---|
| **1. オブジェクトは知覚でき、直接操作できる** | ユーザーが画面上でオブジェクトを視覚的に認識し、直接触れて操作できる |
| **2. オブジェクトは自身の属性と状態を持つ** | 各オブジェクトが「自分は何であるか」「今どういう状態か」を視覚的に表現する |
| **3. オブジェクトの選択がアクションの選択に先行する** | 常に「名詞→動詞」の順序。ユーザーはまず対象を選び、次に操作を選ぶ |
| **4. すべてのオブジェクトが協調してUIを構成する** | オブジェクトは孤立せず、関係性を持ちながら全体として一貫したUIを形成する |

### 1.3 OOUIの設計プロセス（3ステップ）

```
Step 1: オブジェクトの抽出
  要件から名詞を抽出 → 属性・アクション・関係性を定義

Step 2: ビューの設計
  各オブジェクトに「コレクションビュー」と「シングルビュー」を設計

Step 3: レイアウト・ナビゲーション
  ビューを画面に配置し、ナビゲーション構造を設計
```

### 1.4 コレクションビューとシングルビュー

OOUIの基本的な画面パターン:

- **コレクションビュー**: オブジェクトの一覧表示（リスト/グリッド）。必要最小限の属性のみ表示
- **シングルビュー**: オブジェクト1つの詳細表示。全属性とアクションを提供

```
[コレクションビュー: オブジェクト一覧]
        |
        v  （1つ選択）
[シングルビュー: オブジェクト詳細 + アクション]
        |
        v  （関連オブジェクトへ遷移）
[コレクションビュー: 関連オブジェクト一覧]
```

---

## 2. オブジェクト抽出

### 2.1 MVP要件からの名詞抽出

MVP要件書から名詞を抽出し、UIオブジェクトとして適格かを判定する。

| 抽出した名詞 | UIオブジェクトか | 判定理由 |
|---|---|---|
| カメラ | **Yes** | ユーザーが直接操作する主要オブジェクト |
| 写真 | **Yes** | 撮影結果として複数インスタンスが生成される |
| フラッシュ | No（属性） | カメラの状態属性（オン/オフ）であり独立オブジェクトではない |
| カメラ位置 | No（属性） | カメラの状態属性（前面/背面）であり独立オブジェクトではない |
| フィルター | No（属性） | MVPではiPhone 4固定のため選択対象にならない |
| シャッター | No（アクション） | 「撮影する」というアクションのUIトリガー |
| カメラロール | No（外部） | OSのPhotosアプリが管理する外部オブジェクト |

### 2.2 Phase 2要件からの名詞抽出

| 抽出した名詞 | UIオブジェクトか | 判定理由 |
|---|---|---|
| カメラ機種 | **Yes** | iPhone 4, 5s, 6等の複数インスタンス。ユーザーが選択する |
| テーマ | No（属性） | カメラ機種に紐づくUI外観。機種選択で自動決定 |
| 動画 | **Yes** | 写真と同様に複数インスタンスが生成される |
| ギャラリー | **Yes** | 撮影した写真/動画のコレクション表示 |
| フィルター設定 | No（属性） | カメラ機種に紐づくフィルターパラメータ群 |

### 2.3 オブジェクト一覧

| # | オブジェクト | フェーズ | 説明 |
|---|---|---|---|
| O-1 | **Camera** | MVP | 撮影セッション。ユーザーが操作する主体 |
| O-2 | **Photo** | MVP | 撮影された写真。フィルター適用済みの画像 |
| O-3 | **CameraModel** | Phase 2 | 再現対象のiPhone機種（iPhone 4, 5s, 6等） |
| O-4 | **Video** | Phase 2 | 撮影された動画 |
| O-5 | **Gallery** | Phase 2 | 撮影した写真/動画のアプリ内コレクション |

---

## 3. オブジェクト定義

### 3.1 Camera（カメラ）

ユーザーが直接操作するメインオブジェクト。本アプリの中核。

| 区分 | 項目 | 型 / 値 | 説明 |
|---|---|---|---|
| **属性** | position | `.back` / `.front` | 背面/前面カメラ |
| | flashMode | `.on` / `.off` | フラッシュ状態（前面カメラ時は`.off`固定） |
| | isCapturing | `Bool` | 撮影中かどうか |
| | currentModel | `CameraModel` | 現在の再現機種（MVPではiPhone 4固定） |
| | previewStream | `AsyncStream<CIImage>` | リアルタイムプレビューのフレーム |
| **アクション** | capture() | → `Photo` | シャッターを切り、写真を生成する |
| | toggleFlash() | | フラッシュのオン/オフを切り替える |
| | switchPosition() | | 前面/背面カメラを切り替える |
| | changeModel() | | 再現機種を変更する（Phase 2） |

#### ビュー設計

| ビュー種別 | 適用 | 理由 |
|---|---|---|
| コレクションビュー | **なし** | カメラは常に1つ（デバイスのカメラ）。一覧表示の必要がない |
| シングルビュー | **カメラ画面（メイン画面）** | ファインダー + コントロール。常にこのビューが表示される |

> **注**: カメラはOOUIにおいて特殊なオブジェクトである。通常のOOUIは「コレクション→シングル」の遷移だが、カメラは常にシングルビューのみで存在する「ツール型オブジェクト」にあたる。

---

### 3.2 Photo（写真）

撮影アクションによって生成されるオブジェクト。

| 区分 | 項目 | 型 / 値 | 説明 |
|---|---|---|---|
| **属性** | image | `UIImage` | フィルター適用済みの画像データ |
| | capturedAt | `Date` | 撮影日時 |
| | cameraModel | `CameraModel` | 撮影に使用した再現機種 |
| | position | `.back` / `.front` | 撮影時のカメラ位置 |
| | flashUsed | `Bool` | フラッシュ使用有無 |
| | resolution | `CGSize` | 出力解像度（2592×1936px） |
| **アクション** | save() | | カメラロールに保存する |
| | share() | | OSのシェアシートで共有する（Phase 2） |

#### ビュー設計

| ビュー種別 | MVP | Phase 2 |
|---|---|---|
| コレクションビュー | なし（カメラロールに委任） | **ギャラリー画面**（グリッド表示） |
| シングルビュー | **サムネイル**（直近1枚を下部に表示） | **写真詳細画面**（フルスクリーン表示 + アクション） |

---

### 3.3 CameraModel（カメラ機種）— Phase 2

再現対象のiPhone機種を表すオブジェクト。

| 区分 | 項目 | 型 / 値 | 説明 |
|---|---|---|---|
| **属性** | name | `String` | 機種名（"iPhone 4", "iPhone 5s"等） |
| | era | `String` | 対応iOS世代（"iOS 4-6", "iOS 7"等） |
| | year | `Int` | 発売年 |
| | megapixels | `Double` | カメラ画素数 |
| | focalLength | `Double` | 焦点距離（mm換算） |
| | filterParams | `FilterParameters` | フィルターパラメータ群（色味、ノイズ等） |
| | themeStyle | `ThemeStyle` | UIテーマ（スキューモーフィズム / フラット等） |
| | isPurchased | `Bool` | 購入済みかどうか（課金要素） |
| | thumbnail | `Image` | 機種のサムネイル画像 |
| **アクション** | select() | | この機種をカメラに適用する |
| | preview() | | フィルター効果をプレビューする |
| | purchase() | | 機種を購入する（ロック解除） |

#### ビュー設計

| ビュー種別 | 画面 | 説明 |
|---|---|---|
| コレクションビュー | **機種選択画面** | 横スクロールカルーセルまたはグリッド。各機種のサムネイルと名前を表示 |
| シングルビュー | **機種詳細画面** | 機種の詳細情報 + フィルタープレビュー + 選択/購入ボタン |

---

### 3.4 Video（動画）— Phase 2

撮影された動画オブジェクト。Photoと類似の構造。

| 区分 | 項目 | 型 / 値 | 説明 |
|---|---|---|---|
| **属性** | videoURL | `URL` | 動画ファイルのURL |
| | duration | `TimeInterval` | 再生時間 |
| | capturedAt | `Date` | 撮影日時 |
| | cameraModel | `CameraModel` | 撮影に使用した再現機種 |
| | thumbnail | `UIImage` | サムネイル画像 |
| **アクション** | save() | | カメラロールに保存する |
| | play() | | 動画を再生する |
| | share() | | OSのシェアシートで共有する |

#### ビュー設計

| ビュー種別 | 画面 | 説明 |
|---|---|---|
| コレクションビュー | **ギャラリー画面**（Photoと共有） | グリッド表示。動画には再生時間バッジを表示 |
| シングルビュー | **動画再生画面** | フルスクリーン再生 + アクション |

---

### 3.5 Gallery（ギャラリー）— Phase 2

撮影した写真・動画を閲覧するためのコレクションオブジェクト。

| 区分 | 項目 | 型 / 値 | 説明 |
|---|---|---|---|
| **属性** | items | `[Photo \| Video]` | ギャラリー内の写真・動画一覧 |
| | sortOrder | `.newest` / `.oldest` | 並び順 |
| | filterByModel | `CameraModel?` | 機種でフィルタリング |
| **アクション** | open() | | ギャラリー画面を開く |

> **注**: GalleryはPhoto/Videoのコレクションを管理する「コンテナオブジェクト」であり、Gallery自体のシングルビューは不要。

---

## 4. オブジェクト関係図

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  ┌──────────┐    currentModel   ┌─────────────┐ │
│  │  Camera   │─────────────────▶│ CameraModel │ │
│  │          │                   │             │ │
│  │ position │                   │ name        │ │
│  │ flash    │                   │ era         │ │
│  │          │                   │ filterParams│ │
│  └────┬─────┘                   │ themeStyle  │ │
│       │ capture()               └─────────────┘ │
│       │                                         │
│       ▼                                         │
│  ┌──────────┐                   ┌─────────────┐ │
│  │  Photo   │◀─────────────────▶│   Video     │ │
│  │          │   同一ギャラリー    │             │ │
│  │ image    │      に共存       │ videoURL    │ │
│  │ capturedAt│                   │ duration    │ │
│  └────┬─────┘                   └──────┬──────┘ │
│       │                                │        │
│       └──────────┬─────────────────────┘        │
│                  ▼                               │
│           ┌──────────┐                           │
│           │ Gallery  │                           │
│           │          │                           │
│           │ items    │                           │
│           │ sortOrder│                           │
│           └──────────┘                           │
│                                                 │
│  ───── MVP ─────── │ ──── Phase 2 ──────────── │
│  Camera, Photo      │ CameraModel, Video,       │
│                     │ Gallery                    │
└─────────────────────────────────────────────────┘
```

### 関係性の説明

| 関係 | 種類 | 説明 |
|---|---|---|
| Camera → Photo | **生成** | Cameraのcapture()アクションがPhotoを生成する |
| Camera → CameraModel | **参照** | Cameraは現在適用中のCameraModelを参照する |
| Photo → CameraModel | **記録** | Photoは撮影時のCameraModelを記録する |
| Camera → Video | **生成**（Phase 2） | Cameraの録画アクションがVideoを生成する |
| Gallery → Photo/Video | **集約** | GalleryはPhoto/Videoのコレクションを管理する |
| CameraModel → ThemeStyle | **所有** | CameraModelがUIテーマを決定する |

---

## 5. ビューマッピング（画面設計）

### 5.1 MVP画面構成

MVPでは**Camera**と**Photo**の2オブジェクトのみ。単一画面で完結する。

```
┌─────────────────────────────────────────┐
│            Camera（シングルビュー）        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 上部: Camera属性の操作            │    │
│  │   [flashMode切替] [position切替] │    │
│  ├─────────────────────────────────┤    │
│  │ 中央: Camera.previewStream       │    │
│  │   （リアルタイムプレビュー）        │    │
│  ├─────────────────────────────────┤    │
│  │ 下部: Cameraアクション            │    │
│  │   [Photo(直近)] [capture()]      │    │
│  └─────────────────────────────────┘    │
│                                         │
└─────────────────────────────────────────┘
```

**OOUIの観点での整理:**

| 画面要素 | OOUIマッピング | 説明 |
|---|---|---|
| ファインダー | Camera.previewStream（属性の表示） | カメラオブジェクトの現在状態をリアルタイム表示 |
| フラッシュボタン | Camera.toggleFlash()（アクション） | Camera属性flashModeを操作するボタン |
| カメラ切替ボタン | Camera.switchPosition()（アクション） | Camera属性positionを操作するボタン |
| シャッターボタン | Camera.capture()（アクション） | Photoオブジェクトを生成するアクション |
| サムネイル | Photo（シングルビューの縮小版） | 直近のPhotoオブジェクトを表示。タップでカメラロール遷移 |

### 5.2 Phase 2 画面構成

Phase 2では**CameraModel**、**Gallery**が追加され、画面遷移が発生する。

```
[Camera画面]                    ← メイン画面（常時表示）
  │
  ├──▶ [CameraModel一覧]       ← CameraModelコレクションビュー
  │       │
  │       └──▶ [CameraModel詳細] ← CameraModelシングルビュー
  │
  └──▶ [Gallery画面]            ← Photo/Videoコレクションビュー
          │
          ├──▶ [Photo詳細]      ← Photoシングルビュー
          └──▶ [Video再生]      ← Videoシングルビュー
```

#### 各画面の詳細

**Camera画面（メイン画面 — 拡張版）**

| 追加要素 | OOUIマッピング |
|---|---|
| 機種切替ボタン | Camera.changeModel() → CameraModelコレクションビューへ遷移 |
| 撮影モード切替 | Camera属性の操作（写真/動画） |
| ギャラリーボタン | Gallery.open() → Galleryコレクションビューへ遷移 |

**CameraModel一覧画面（コレクションビュー）**

| 要素 | 表示内容 |
|---|---|
| 各セルの情報 | thumbnail, name, year |
| ロック表示 | isPurchased == false の場合ロックアイコン |
| 選択状態 | currentModel と一致する機種にチェックマーク |
| タップアクション | select()（購入済み）または purchase()（未購入） |

**Gallery画面（コレクションビュー）**

| 要素 | 表示内容 |
|---|---|
| グリッドセル | Photo.image / Video.thumbnail |
| 動画バッジ | Video.duration を表示 |
| フィルタリング | CameraModelで絞り込み可能 |
| タップアクション | Photo詳細 or Video再生へ遷移 |

---

## 6. ナビゲーション構造

### 6.1 MVP: フラットナビゲーション

```
[Camera画面] ──（サムネイルタップ）──▶ [カメラロール（OS）]
```

- 画面遷移は実質1つのみ
- カメラロールはOSのシステム画面に委任

### 6.2 Phase 2: タブ + 階層ナビゲーション

```
┌──────────────────────────────────────────┐
│              タブバー（OOUI原則に基づく）     │
│                                          │
│  [📷 カメラ]  [📱 機種]  [🖼 ギャラリー]   │
│    Camera     CameraModel    Gallery     │
│   （名詞）     （名詞）      （名詞）       │
└──────────────────────────────────────────┘
```

**OOUIに基づくタブ設計:**
- タブのラベルは**すべて名詞（オブジェクト名）** にする
- 「撮影する」「設定」「共有」などの動詞・タスク名をタブにしない
- 各タブが1つのオブジェクトのコレクションビュー（またはシングルビュー）に対応する

> **注**: タブバーのビジュアルはPhase 2でも引き続きレトロUI（iOS 4〜6風）で実装する。タブという**構造**はHIG/OOUIに準拠しつつ、**見た目**はスキューモーフィズムで再現する。

---

## 7. コードへのマッピング

OOUIオブジェクトは、MVVMアーキテクチャに以下のように対応する。

### 7.1 ディレクトリ構成

```
OldIPhoneCameraExperience/
├── Models/
│   ├── Camera.swift          ← O-1: Camera
│   ├── Photo.swift           ← O-2: Photo
│   ├── CameraModel.swift     ← O-3: CameraModel (Phase 2)
│   ├── Video.swift           ← O-4: Video (Phase 2)
│   └── Gallery.swift         ← O-5: Gallery (Phase 2)
├── ViewModels/
│   ├── CameraViewModel.swift
│   ├── PhotoViewModel.swift
│   ├── CameraModelViewModel.swift  (Phase 2)
│   └── GalleryViewModel.swift      (Phase 2)
├── Views/
│   ├── Camera/
│   │   ├── CameraView.swift          ← Camera シングルビュー
│   │   ├── CameraPreviewView.swift   ← Camera.previewStream 表示
│   │   ├── ShutterButton.swift       ← Camera.capture() トリガー
│   │   ├── FlashToggle.swift         ← Camera.toggleFlash() トリガー
│   │   └── CameraPositionToggle.swift ← Camera.switchPosition() トリガー
│   ├── Photo/
│   │   ├── PhotoThumbnail.swift      ← Photo シングルビュー（縮小）
│   │   └── PhotoDetailView.swift     ← Photo シングルビュー（Phase 2）
│   ├── CameraModel/               (Phase 2)
│   │   ├── CameraModelListView.swift ← CameraModel コレクションビュー
│   │   └── CameraModelDetailView.swift ← CameraModel シングルビュー
│   └── Gallery/                    (Phase 2)
│       └── GalleryView.swift        ← Gallery コレクションビュー
└── Services/
    ├── CameraService.swift          ← AVFoundation制御
    ├── FilterService.swift          ← Core Image フィルター処理
    └── PhotoLibraryService.swift    ← Photos Framework 保存
```

### 7.2 命名規則

OOUIオブジェクト名をコードベース全体で統一する。

| OOUIオブジェクト | Model | ViewModel | View | Service |
|---|---|---|---|---|
| Camera | `Camera` | `CameraViewModel` | `CameraView` | `CameraService` |
| Photo | `Photo` | `PhotoViewModel` | `PhotoThumbnail` | `PhotoLibraryService` |
| CameraModel | `CameraModel` | `CameraModelViewModel` | `CameraModelListView` | — |
| Video | `Video` | — | — | — |
| Gallery | `Gallery` | `GalleryViewModel` | `GalleryView` | — |

**命名で避けるべき表記揺れ:**

| OOUIオブジェクト | 正 | 誤（使わない） |
|---|---|---|
| Photo | `Photo`, `photo` | `image`, `picture`, `capture`, `shot` |
| Camera | `Camera`, `camera` | `cam`, `shooter`, `recorder` |
| CameraModel | `CameraModel`, `cameraModel` | `device`, `phone`, `iPhone`, `model` |

> **例外**: `UIImage`や`CIImage`などのフレームワーク型はそのまま使用する。これらはOOUIオブジェクトではなく実装上のデータ型である。

---

## 8. OOUI設計チェックリスト

実装時に以下を確認する。

### オブジェクトの原則

- [ ] すべてのUIオブジェクトが画面上で視覚的に認識できるか
- [ ] オブジェクトの現在状態が視覚的に表現されているか（例: フラッシュのオン/オフ）
- [ ] ユーザーはオブジェクトを選んでからアクションを選んでいるか（名詞→動詞）
- [ ] タスク指向の画面フロー（動詞→名詞）になっていないか

### ビューの原則

- [ ] 各オブジェクトにコレクションビューとシングルビューが設計されているか（該当する場合）
- [ ] コレクションビューには必要最小限の属性のみ表示しているか
- [ ] シングルビューではすべてのアクションにアクセスできるか

### ナビゲーションの原則

- [ ] メインナビゲーション（タブ等）のラベルはオブジェクト名（名詞）か
- [ ] コレクション→シングルの遷移が直感的か
- [ ] ユーザーが目的のオブジェクトに2タップ以内でたどり着けるか

### コードの原則

- [ ] OOUIオブジェクト名がModel/ViewModel/View全体で統一されているか
- [ ] 表記揺れ（7.2節参照）がないか
- [ ] 新しい機能を追加する際、既存オブジェクトの拡張か新オブジェクトの追加かを判断しているか
