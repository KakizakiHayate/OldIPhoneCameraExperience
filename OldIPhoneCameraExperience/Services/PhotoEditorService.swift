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

    /// 矩形でクロップする
    func cropImage(_ image: CIImage, rect: CGRect) -> CIImage?

    /// アスペクト比でクロップする
    func cropImage(_ image: CIImage, aspectRatio: AspectRatio, in bounds: CGRect) -> CIImage?
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

// MARK: - Crop

extension PhotoEditorService {
    func cropImage(_ image: CIImage, rect: CGRect) -> CIImage? {
        let extent = image.extent

        // 幅・高さ0以下の場合はnilを返す
        guard rect.width > 0, rect.height > 0 else { return nil }

        // 矩形を画像範囲にクランプ
        var clampedRect = rect.intersection(extent)

        // intersection が空の場合
        guard !clampedRect.isNull, !clampedRect.isEmpty else { return nil }

        // 最小サイズを適用
        let minSize = EditorConstants.minimumCropSize
        if clampedRect.width < minSize {
            clampedRect.size.width = min(minSize, extent.width)
        }
        if clampedRect.height < minSize {
            clampedRect.size.height = min(minSize, extent.height)
        }

        // クランプ後に画像範囲を超えないように再調整
        if clampedRect.maxX > extent.maxX {
            clampedRect.origin.x = extent.maxX - clampedRect.width
        }
        if clampedRect.maxY > extent.maxY {
            clampedRect.origin.y = extent.maxY - clampedRect.height
        }

        return image.cropped(to: clampedRect)
    }

    func cropImage(_ image: CIImage, aspectRatio: AspectRatio, in bounds: CGRect) -> CIImage? {
        let targetRatio = aspectRatio.widthRatio / aspectRatio.heightRatio
        let currentRatio = bounds.width / bounds.height

        let cropRect: CGRect
        if currentRatio > targetRatio {
            // 画像が横長すぎる → 幅をカット
            let newWidth = bounds.height * targetRatio
            let xOffset = (bounds.width - newWidth) / 2
            cropRect = CGRect(x: bounds.minX + xOffset, y: bounds.minY, width: newWidth, height: bounds.height)
        } else {
            // 画像が縦長すぎる → 高さをカット
            let newHeight = bounds.width / targetRatio
            let yOffset = (bounds.height - newHeight) / 2
            cropRect = CGRect(x: bounds.minX, y: bounds.minY + yOffset, width: bounds.width, height: newHeight)
        }

        return image.cropped(to: cropRect)
    }
}

// MARK: - Float Clamping

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
