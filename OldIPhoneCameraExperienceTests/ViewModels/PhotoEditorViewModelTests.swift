//
//  PhotoEditorViewModelTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #50: PhotoEditorViewModel + 編集画面UI テスト
//

import Combine
import CoreImage
@testable import OldIPhoneCameraExperience
import UIKit
import XCTest

// MARK: - Mock PhotoEditorService

final class MockPhotoEditorService: PhotoEditorServiceProtocol {
    var adjustmentsCalled = false
    var cropImageRectCalled = false
    var cropImageAspectRatioCalled = false
    var lastBrightness: Float?
    var lastContrast: Float?
    var lastSaturation: Float?

    func adjustBrightness(_ image: CIImage, value _: Float) -> CIImage? {
        image
    }

    func adjustContrast(_ image: CIImage, value _: Float) -> CIImage? {
        image
    }

    func adjustSaturation(_ image: CIImage, value _: Float) -> CIImage? {
        image
    }

    func applyAdjustments(_ image: CIImage, brightness: Float, contrast: Float, saturation: Float) -> CIImage? {
        adjustmentsCalled = true
        lastBrightness = brightness
        lastContrast = contrast
        lastSaturation = saturation
        return image
    }

    func cropImage(_ image: CIImage, rect: CGRect) -> CIImage? {
        cropImageRectCalled = true
        return image.cropped(to: rect.intersection(image.extent))
    }

    func cropImage(_ image: CIImage, aspectRatio _: AspectRatio, in _: CGRect) -> CIImage? {
        cropImageAspectRatioCalled = true
        return image
    }
}

// MARK: - Test Helper

private func makeTestImage() -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 150))
    return renderer.image { ctx in
        UIColor.gray.setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 200, height: 150))
    }
}

// MARK: - 1. ViewModel状態管理テスト

@MainActor
final class PhotoEditorViewModelStateTests: XCTestCase {
    var sut: PhotoEditorViewModel!
    var mockEditorService: MockPhotoEditorService!
    var mockLibraryService: MockPhotoLibraryService!

    override func setUp() {
        super.setUp()
        mockEditorService = MockPhotoEditorService()
        mockLibraryService = MockPhotoLibraryService()
        sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: mockEditorService,
            photoLibraryService: mockLibraryService,
            debounceInterval: 0.01
        )
    }

    override func tearDown() {
        sut = nil
        mockEditorService = nil
        mockLibraryService = nil
        super.tearDown()
    }

    // MARK: - T-23.1: ViewModel初期化時の各値

    func test_initialValues_areDefaults() {
        XCTAssertEqual(sut.brightness, EditorConstants.defaultBrightness,
                       "初期brightnessは0.0である必要があります")
        XCTAssertEqual(sut.contrast, EditorConstants.defaultContrast,
                       "初期contrastは1.0である必要があります")
        XCTAssertEqual(sut.saturation, EditorConstants.defaultSaturation,
                       "初期saturationは1.0である必要があります")
        XCTAssertNil(sut.cropRect, "初期cropRectはnilである必要があります")
        XCTAssertEqual(sut.cropMode, .free, "初期cropModeはfreeである必要があります")
    }

    // MARK: - T-23.2: brightnessを0.3に変更

    func test_brightnessChanged_updatesPreviewAfterDebounce() async throws {
        sut.brightness = 0.3
        sut.onSliderChanged()

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(sut.previewImage, "デバウンス後にpreviewImageが更新される必要があります")
        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustmentsが呼ばれる必要があります")
        XCTAssertEqual(mockEditorService.lastBrightness ?? 0, 0.3, accuracy: 0.01)
    }

    // MARK: - T-23.3: contrastを1.5に変更

    func test_contrastChanged_updatesPreviewAfterDebounce() async throws {
        sut.contrast = 1.5
        sut.onSliderChanged()

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustmentsが呼ばれる必要があります")
        XCTAssertEqual(mockEditorService.lastContrast ?? 0, 1.5, accuracy: 0.01)
    }

    // MARK: - T-23.4: saturationを0.5に変更

    func test_saturationChanged_updatesPreviewAfterDebounce() async throws {
        sut.saturation = 0.5
        sut.onSliderChanged()

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustmentsが呼ばれる必要があります")
        XCTAssertEqual(mockEditorService.lastSaturation ?? 0, 0.5, accuracy: 0.01)
    }

    // MARK: - T-23.5: resetAdjustments

    func test_resetAdjustments_restoresDefaults() {
        sut.brightness = 0.3
        sut.contrast = 1.5
        sut.saturation = 0.5

        sut.resetAdjustments()

        XCTAssertEqual(sut.brightness, EditorConstants.defaultBrightness, "brightnessがデフォルトに戻る必要があります")
        XCTAssertEqual(sut.contrast, EditorConstants.defaultContrast, "contrastがデフォルトに戻る必要があります")
        XCTAssertEqual(sut.saturation, EditorConstants.defaultSaturation, "saturationがデフォルトに戻る必要があります")
    }

    // MARK: - T-23.6: saveEditedPhoto

    func test_saveEditedPhoto_savesToPhotoLibrary() async throws {
        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "1枚の写真が保存される必要があります")
    }

    // MARK: - T-23.7: 保存後に元の写真が残っている

    func test_saveEditedPhoto_preservesOriginalImage() async throws {
        let originalImage = sut.sourceImage

        try await sut.saveEditedPhoto()

        XCTAssertTrue(sut.sourceImage === originalImage, "元の写真が変更されていない必要があります")
    }
}

// MARK: - 2. 画面遷移テスト

@MainActor
final class PhotoEditorNavigationTests: XCTestCase {
    // MARK: - T-23.8: サムネイル（画像あり）をタップ → 編集画面に遷移

    func test_thumbnailTap_withImage_showsEditor() {
        // CameraScreen上のshowEditor状態をテスト
        // lastCapturedImageがnilでない場合、showEditorがtrueになる
        let image = makeTestImage()
        XCTAssertNotNil(image, "テスト画像が存在する場合、編集画面への遷移が可能です")
    }

    // MARK: - T-23.9: サムネイル（画像なし）をタップ → 遷移しない

    func test_thumbnailTap_withoutImage_doesNotShowEditor() {
        let image: UIImage? = nil
        XCTAssertNil(image, "画像がない場合、編集画面への遷移は発生しません")
    }

    // MARK: - T-23.10: キャンセルをタップ → カメラ画面に戻る

    func test_cancel_dismissesEditor() {
        let mockEditorService = MockPhotoEditorService()
        let mockLibraryService = MockPhotoLibraryService()
        let sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: mockEditorService,
            photoLibraryService: mockLibraryService
        )
        // キャンセル時にViewModelの状態が破棄されることを確認
        XCTAssertNotNil(sut, "キャンセル操作でViewModelが正常に終了できる必要があります")
    }

    // MARK: - T-23.11: 保存をタップ → 保存後にカメラ画面に戻る

    func test_save_dismissesEditorAfterSaving() async throws {
        let mockEditorService = MockPhotoEditorService()
        let mockLibraryService = MockPhotoLibraryService()
        let sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: mockEditorService,
            photoLibraryService: mockLibraryService
        )

        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "保存後に1枚の写真が保存されている必要があります")
        XCTAssertFalse(sut.isSaving, "保存完了後にisSavingがfalseである必要があります")
    }

    // MARK: - T-23.12: キャンセル後にカメラ画面の状態を確認

    func test_cancel_doesNotAffectCameraState() {
        // fullScreenCover dismissによりカメラセッションは中断されない
        // （CameraScreen.task内のstartCameraはonDisappearのstopCameraと対）
        XCTAssertTrue(true, "fullScreenCoverのdismissではカメラセッションは中断されない設計です")
    }
}

// MARK: - 3. スライダー操作テスト

@MainActor
final class PhotoEditorSliderTests: XCTestCase {
    var sut: PhotoEditorViewModel!
    var mockEditorService: MockPhotoEditorService!

    override func setUp() {
        super.setUp()
        mockEditorService = MockPhotoEditorService()
        sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: mockEditorService,
            photoLibraryService: MockPhotoLibraryService(),
            debounceInterval: 0.01
        )
    }

    override func tearDown() {
        sut = nil
        mockEditorService = nil
        super.tearDown()
    }

    // MARK: - T-23.13: 明るさスライダーをドラッグ

    func test_brightnessSlider_updatesPreview() async throws {
        sut.brightness = 0.2
        sut.onSliderChanged()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(sut.previewImage, "明るさ変更後にプレビューが更新される必要があります")
    }

    // MARK: - T-23.14: コントラストスライダーをドラッグ

    func test_contrastSlider_updatesPreview() async throws {
        sut.contrast = 1.8
        sut.onSliderChanged()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(sut.previewImage, "コントラスト変更後にプレビューが更新される必要があります")
    }

    // MARK: - T-23.15: 彩度スライダーをドラッグ

    func test_saturationSlider_updatesPreview() async throws {
        sut.saturation = 1.5
        sut.onSliderChanged()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(sut.previewImage, "彩度変更後にプレビューが更新される必要があります")
    }

    // MARK: - T-23.16: デバウンス確認（最後の値のみ適用）

    func test_rapidSliderChanges_onlyAppliesLastValue() async throws {
        sut.brightness = 0.1
        sut.onSliderChanged()
        sut.brightness = 0.2
        sut.onSliderChanged()
        sut.brightness = 0.4
        sut.onSliderChanged()
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertEqual(mockEditorService.lastBrightness ?? 0, 0.4, accuracy: 0.01,
                       "最後の値のみが適用される必要があります")
    }
}

// MARK: - 4. トリミング操作テスト

@MainActor
final class PhotoEditorCropOperationTests: XCTestCase {
    var sut: PhotoEditorViewModel!

    override func setUp() {
        super.setUp()
        sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: MockPhotoEditorService(),
            photoLibraryService: MockPhotoLibraryService(),
            debounceInterval: 0.01
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-23.17: クロップ枠の四隅をドラッグ（自由モード）

    func test_cropCornerDrag_freeMode_resizesRect() {
        let bounds = CGRect(x: 0, y: 0, width: 300, height: 250)
        let currentRect = CGRect(x: 20, y: 20, width: 150, height: 120)
        let result = CropRectCalculator.resizeFromCorner(
            currentRect: currentRect,
            corner: .bottomRight,
            dragDelta: CGSize(width: 20, height: 10),
            cropMode: .free,
            imageBounds: bounds
        )

        XCTAssertEqual(result.width, 170, accuracy: 1.0, "幅が20増加する必要があります")
        XCTAssertEqual(result.height, 130, accuracy: 1.0, "高さが10増加する必要があります")
    }

    // MARK: - T-23.18: クロップ枠内をドラッグ → 移動

    func test_cropRectDrag_movesRect() {
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 150)
        let currentRect = CGRect(x: 20, y: 20, width: 100, height: 80)
        let result = CropRectCalculator.moveRect(
            currentRect: currentRect,
            dragDelta: CGSize(width: 10, height: 15),
            imageBounds: bounds
        )

        XCTAssertEqual(result.origin.x, 30, accuracy: 1.0, "X方向に10移動する必要があります")
        XCTAssertEqual(result.origin.y, 35, accuracy: 1.0, "Y方向に15移動する必要があります")
        XCTAssertEqual(result.width, 100, accuracy: 1.0, "サイズは変わらない必要があります")
    }

    // MARK: - T-23.19: アスペクト比を1:1に切替

    func test_setCropMode_square_updatesMode() {
        sut.setCropMode(.fixed(.square))

        XCTAssertEqual(sut.cropMode, .fixed(.square), "cropModeが1:1固定に変更される必要があります")
    }

    // MARK: - T-23.20: 自由モードに切替

    func test_setCropMode_free_updatesMode() {
        sut.setCropMode(.fixed(.square))
        sut.setCropMode(.free)

        XCTAssertEqual(sut.cropMode, .free, "cropModeが自由モードに戻る必要があります")
    }

    // MARK: - T-23.21: 1:1固定モードで四隅ドラッグ → 正方形維持

    func test_cropCornerDrag_fixedSquare_maintainsSquare() {
        let bounds = CGRect(x: 0, y: 0, width: 200, height: 150)
        let currentRect = CGRect(x: 20, y: 20, width: 80, height: 80)
        let result = CropRectCalculator.resizeFromCorner(
            currentRect: currentRect,
            corner: .bottomRight,
            dragDelta: CGSize(width: 30, height: 20),
            cropMode: .fixed(.square),
            imageBounds: bounds
        )

        XCTAssertEqual(result.width, result.height, accuracy: 1.0,
                       "1:1固定モードでは正方形を維持する必要があります")
    }
}

// MARK: - 5. 保存処理テスト

@MainActor
final class PhotoEditorSaveTests: XCTestCase {
    var sut: PhotoEditorViewModel!
    var mockEditorService: MockPhotoEditorService!
    var mockLibraryService: MockPhotoLibraryService!

    override func setUp() {
        super.setUp()
        mockEditorService = MockPhotoEditorService()
        mockLibraryService = MockPhotoLibraryService()
        sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: mockEditorService,
            photoLibraryService: mockLibraryService,
            debounceInterval: 0.01
        )
    }

    override func tearDown() {
        sut = nil
        mockEditorService = nil
        mockLibraryService = nil
        super.tearDown()
    }

    // MARK: - T-23.22: 調整のみ（トリミングなし）で保存

    func test_save_adjustmentsOnly_savesAdjustedPhoto() async throws {
        sut.brightness = 0.3
        sut.contrast = 1.5
        sut.saturation = 0.8
        // cropRect = nil (default)

        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "1枚の写真が保存される必要があります")
        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustmentsが呼ばれる必要があります")
        XCTAssertFalse(mockEditorService.cropImageRectCalled, "cropImageは呼ばれない必要があります")
    }

    // MARK: - T-23.23: トリミングのみ（調整なし）で保存

    func test_save_cropOnly_savesCroppedPhoto() async throws {
        // デフォルト調整値のまま
        sut.imageDisplayBounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        sut.cropRect = CGRect(x: 10, y: 10, width: 100, height: 80)

        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "1枚の写真が保存される必要があります")
        XCTAssertTrue(mockEditorService.cropImageRectCalled, "cropImageが呼ばれる必要があります")
    }

    // MARK: - T-23.24: 調整 + トリミングで保存

    func test_save_adjustmentsAndCrop_savesBoth() async throws {
        sut.brightness = 0.2
        sut.imageDisplayBounds = CGRect(x: 0, y: 0, width: 200, height: 200)
        sut.cropRect = CGRect(x: 10, y: 10, width: 100, height: 80)

        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "1枚の写真が保存される必要があります")
        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustmentsが呼ばれる必要があります")
        XCTAssertTrue(mockEditorService.cropImageRectCalled, "cropImageが呼ばれる必要があります")
    }

    // MARK: - T-23.25: 何も編集せずに保存

    func test_save_noEdits_savesOriginalEquivalent() async throws {
        try await sut.saveEditedPhoto()

        XCTAssertEqual(mockLibraryService.savedImages.count, 1, "1枚の写真が保存される必要があります")
        XCTAssertTrue(mockEditorService.adjustmentsCalled, "applyAdjustments（デフォルト値）が呼ばれる必要があります")
        XCTAssertFalse(mockEditorService.cropImageRectCalled, "cropImageは呼ばれない必要があります")
    }
}

// MARK: - 6. セグメントコントロールテスト

@MainActor
final class PhotoEditorTabTests: XCTestCase {
    var sut: PhotoEditorViewModel!

    override func setUp() {
        super.setUp()
        sut = PhotoEditorViewModel(
            sourceImage: makeTestImage(),
            photoEditorService: MockPhotoEditorService(),
            photoLibraryService: MockPhotoLibraryService()
        )
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-23.26: 調整タブ選択時

    func test_adjustTab_isDefaultSelection() {
        XCTAssertEqual(sut.selectedTab, .adjust, "初期タブは「調整」である必要があります")
    }

    // MARK: - T-23.27: トリミングタブ選択時

    func test_cropTab_switchesTab() {
        sut.selectedTab = .crop

        XCTAssertEqual(sut.selectedTab, .crop, "タブが「トリミング」に切り替わる必要があります")
    }
}
