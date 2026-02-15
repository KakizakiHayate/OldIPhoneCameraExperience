//
//  FilterService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreGraphics
import CoreImage

/// フィルター処理を提供するプロトコル
protocol FilterServiceProtocol {
    /// 暖色系フィルターを適用する
    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// 画角クロップを適用する
    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// すべてのフィルターを適用する（暖色系 → クロップ）
    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// 手ブレシミュレーションを適用する
    func applyShakeEffect(_ image: CIImage, effect: ShakeEffect) -> CIImage?
}

/// フィルター処理の実装
final class FilterService: FilterServiceProtocol {
    private let context = CIContext()

    // MARK: - FilterServiceProtocol

    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let tintIntensity = CGFloat(config.highlightTintIntensity)

        return image
            .applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: config.warmth, y: config.tint)
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: config.saturation
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.0 + tintIntensity, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.0 + tintIntensity * 0.5, z: 0, w: 0)
            ])
    }

    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let inputExtent = image.extent

        // クロップ率に基づいて中央部分を切り出す（26mm→32mm画角変換）
        let cropRatio = CGFloat(config.cropRatio)
        let croppedWidth = inputExtent.width * cropRatio
        let croppedHeight = inputExtent.height * cropRatio

        let cropX = (inputExtent.width - croppedWidth) / 2
        let cropY = (inputExtent.height - croppedHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: croppedWidth, height: croppedHeight)

        return image.cropped(to: cropRect)
    }

    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage? {
        guard var outputImage = applyWarmthFilter(image, config: config) else {
            return nil
        }

        outputImage = applyCrop(outputImage, config: config) ?? outputImage

        return outputImage
    }

    func applyShakeEffect(_ image: CIImage, effect: ShakeEffect) -> CIImage? {
        let originalExtent = image.extent

        // 端ピクセルを無限に引き伸ばし、変換後のエッジに白線が出るのを防止する
        var outputImage = image.clampedToExtent()

        // 1. シフト（平行移動）+ 回転を適用し、元の範囲でクロップ
        // 写真の中身がブレて見える効果を出しつつ、写真の矩形自体は維持する
        let shiftTransform = CGAffineTransform(translationX: effect.shiftX, y: effect.shiftY)
        let rotationRadians = effect.rotation * .pi / 180.0
        let centerX = originalExtent.midX
        let centerY = originalExtent.midY
        let rotationTransform = CGAffineTransform(translationX: centerX, y: centerY)
            .rotated(by: rotationRadians)
            .translatedBy(x: -centerX, y: -centerY)
        let combined = shiftTransform.concatenating(rotationTransform)
        outputImage = outputImage.transformed(by: combined).cropped(to: originalExtent)

        // 2. モーションブラー
        if let motionBlurFilter = CIFilter(name: "CIMotionBlur") {
            motionBlurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            motionBlurFilter.setValue(effect.motionBlurRadius, forKey: kCIInputRadiusKey)
            motionBlurFilter.setValue(effect.motionBlurAngle * .pi / 180.0, forKey: kCIInputAngleKey)
            if let result = motionBlurFilter.outputImage {
                outputImage = result.cropped(to: originalExtent)
            }
        }

        return outputImage
    }
}
