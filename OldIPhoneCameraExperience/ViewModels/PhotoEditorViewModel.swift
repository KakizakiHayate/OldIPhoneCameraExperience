//
//  PhotoEditorViewModel.swift
//  OldIPhoneCameraExperience
//
//  Issue #50: 写真編集ViewModel
//

import Combine
import CoreImage
import SwiftUI

/// 編集画面のタブ
enum EditorTab: CaseIterable {
    case adjust
    case crop

    var displayLabel: String {
        switch self {
        case .adjust: "調整"
        case .crop: "トリミング"
        }
    }
}

/// 写真編集エラー
enum PhotoEditorError: Error {
    case imageConversionFailed
    case adjustmentFailed
}

/// 写真編集画面のViewModel
@MainActor
final class PhotoEditorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var brightness: Float = EditorConstants.defaultBrightness
    @Published var contrast: Float = EditorConstants.defaultContrast
    @Published var saturation: Float = EditorConstants.defaultSaturation
    @Published private(set) var previewImage: UIImage?
    @Published var cropRect: CGRect?
    @Published var cropMode: CropMode = .free
    /// クロップオーバーレイ内の画像表示領域（ビュー座標）
    var imageDisplayBounds: CGRect?
    @Published var selectedTab: EditorTab = .adjust
    @Published private(set) var isSaving: Bool = false

    // MARK: - Source Image

    let sourceImage: UIImage

    // MARK: - Dependencies

    private let photoEditorService: PhotoEditorServiceProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let ciContext = CIContext()
    private let debounceInterval: TimeInterval

    // MARK: - Private

    private let analytics = AnalyticsService.shared
    private var debounceTask: Task<Void, Never>?
    private var previewCIImage: CIImage?

    // MARK: - Initialization

    init(
        sourceImage: UIImage,
        photoEditorService: PhotoEditorServiceProtocol = PhotoEditorService(),
        photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
        debounceInterval: TimeInterval = 0.3
    ) {
        self.sourceImage = sourceImage
        self.photoEditorService = photoEditorService
        self.photoLibraryService = photoLibraryService
        self.debounceInterval = debounceInterval

        setupPreviewImage()
        analytics.logPhotoEditorOpened()
    }

    // MARK: - Public Methods

    /// スライダー変更時のデバウンス付きプレビュー更新
    func onSliderChanged() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let interval = self?.debounceInterval else { return }
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.updatePreview()
        }
    }

    /// プレビュー画像を更新する
    func updatePreview() {
        guard let previewCI = previewCIImage else { return }

        guard let adjusted = photoEditorService.applyAdjustments(
            previewCI, brightness: brightness, contrast: contrast, saturation: saturation
        ) else { return }

        let result: CIImage
        if let cropRect, let imageRect = convertToImageRect(cropRect, imageSize: adjusted.extent.size) {
            result = photoEditorService.cropImage(adjusted, rect: imageRect) ?? adjusted
        } else {
            result = adjusted
        }

        if let cgImage = ciContext.createCGImage(result, from: result.extent) {
            previewImage = UIImage(cgImage: cgImage)
        }
    }

    /// すべての調整をデフォルトに戻す
    func resetAdjustments() {
        brightness = EditorConstants.defaultBrightness
        contrast = EditorConstants.defaultContrast
        saturation = EditorConstants.defaultSaturation
        updatePreview()
    }

    /// クロップモードを変更する
    func setCropMode(_ mode: CropMode) {
        cropMode = mode
    }

    /// フル解像度で調整+クロップを適用して新規写真として保存する
    func saveEditedPhoto() async throws {
        isSaving = true
        defer { isSaving = false }

        guard let fullResCIImage = CIImage(image: sourceImage) else {
            throw PhotoEditorError.imageConversionFailed
        }

        guard let adjusted = photoEditorService.applyAdjustments(
            fullResCIImage, brightness: brightness, contrast: contrast, saturation: saturation
        ) else {
            throw PhotoEditorError.adjustmentFailed
        }

        let result: CIImage
        if let cropRect, let imageRect = convertToImageRect(cropRect, imageSize: adjusted.extent.size) {
            result = photoEditorService.cropImage(adjusted, rect: imageRect) ?? adjusted
        } else {
            result = adjusted
        }

        guard let cgImage = ciContext.createCGImage(result, from: result.extent) else {
            throw PhotoEditorError.imageConversionFailed
        }

        let uiImage = UIImage(cgImage: cgImage)
        try await photoLibraryService.saveToPhotoLibrary(uiImage)
        analytics.logPhotoSaved(
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            cropApplied: cropRect != nil
        )
    }

    // MARK: - Private Methods

    /// ビュー座標のcropRectをCIImage座標に変換する
    private func convertToImageRect(_ viewCropRect: CGRect, imageSize: CGSize) -> CGRect? {
        guard let displayBounds = imageDisplayBounds else { return nil }
        let transformer = CropCoordinateTransformer(
            imageSize: imageSize,
            viewSize: displayBounds.size
        )
        // ビュー内の画像オフセットを差し引いてから変換
        let relativeRect = CGRect(
            x: viewCropRect.origin.x - displayBounds.origin.x,
            y: viewCropRect.origin.y - displayBounds.origin.y,
            width: viewCropRect.width,
            height: viewCropRect.height
        )
        return transformer.toImageRect(relativeRect)
    }

    private func setupPreviewImage() {
        guard let ciImage = CIImage(image: sourceImage) else { return }
        let maxDimension: CGFloat = 800
        let scale = min(maxDimension / ciImage.extent.width, maxDimension / ciImage.extent.height, 1.0)
        if scale < 1.0 {
            previewCIImage = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        } else {
            previewCIImage = ciImage
        }
        updatePreview()
    }
}
