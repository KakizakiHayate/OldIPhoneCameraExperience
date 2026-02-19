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
        let clamped = value.clamped(to: EditorConstants.brightnessRange)
        return image.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: clamped,
            kCIInputContrastKey: EditorConstants.defaultContrast,
            kCIInputSaturationKey: EditorConstants.defaultSaturation
        ])
    }

    func adjustContrast(_ image: CIImage, value: Float) -> CIImage? {
        let clamped = value.clamped(to: EditorConstants.contrastRange)
        return image.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: EditorConstants.defaultBrightness,
            kCIInputContrastKey: clamped,
            kCIInputSaturationKey: EditorConstants.defaultSaturation
        ])
    }

    func adjustSaturation(_ image: CIImage, value: Float) -> CIImage? {
        let clamped = value.clamped(to: EditorConstants.saturationRange)
        return image.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: EditorConstants.defaultBrightness,
            kCIInputContrastKey: EditorConstants.defaultContrast,
            kCIInputSaturationKey: clamped
        ])
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

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
