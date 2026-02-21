//
//  PhotoEditorService.swift
//  OldIPhoneCameraExperience
//
//  Issue #48: 写真編集サービス
//

import CoreImage

/// 写真編集処理を提供するプロトコル
protocol PhotoEditorServiceProtocol {
    /// 明るさを調整する
    func adjustBrightness(_ image: CIImage, value: Float) -> CIImage?

    /// コントラストを調整する
    func adjustContrast(_ image: CIImage, value: Float) -> CIImage?

    /// 彩度を調整する
    func adjustSaturation(_ image: CIImage, value: Float) -> CIImage?

    /// 明るさ・コントラスト・彩度を一括調整する
    func applyAdjustments(_ image: CIImage, brightness: Float, contrast: Float, saturation: Float) -> CIImage?
}

/// 写真編集処理の実装
final class PhotoEditorService: PhotoEditorServiceProtocol {
    func adjustBrightness(_ image: CIImage, value: Float) -> CIImage? {
        applyAdjustments(image, brightness: value, contrast: EditorConstants.defaultContrast, saturation: EditorConstants.defaultSaturation)
    }

    func adjustContrast(_ image: CIImage, value: Float) -> CIImage? {
        applyAdjustments(image, brightness: EditorConstants.defaultBrightness, contrast: value, saturation: EditorConstants.defaultSaturation)
    }

    func adjustSaturation(_ image: CIImage, value: Float) -> CIImage? {
        applyAdjustments(image, brightness: EditorConstants.defaultBrightness, contrast: EditorConstants.defaultContrast, saturation: value)
    }

    func applyAdjustments(_ image: CIImage, brightness: Float, contrast: Float, saturation: Float) -> CIImage? {
        let clampedBrightness = brightness.clamped(to: EditorConstants.brightnessRange)
        let clampedContrast = contrast.clamped(to: EditorConstants.contrastRange)
        let clampedSaturation = saturation.clamped(to: EditorConstants.saturationRange)

        return image.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: clampedBrightness,
            kCIInputContrastKey: clampedContrast,
            kCIInputSaturationKey: clampedSaturation
        ])
    }
}

// MARK: - Float Clamping

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
