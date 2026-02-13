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

        // 1. クロップ率に基づいて中央部分を切り出す
        let cropRatio = CGFloat(config.cropRatio)
        let croppedWidth = inputExtent.width * cropRatio
        let croppedHeight = inputExtent.height * cropRatio

        let cropX = (inputExtent.width - croppedWidth) / 2
        let cropY = (inputExtent.height - croppedHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: croppedWidth, height: croppedHeight)

        let croppedImage = image.cropped(to: cropRect)

        // 2. 出力解像度にスケーリング
        // CILanczosScaleTransform: scale は均一スケーリング、aspectRatio は水平方向の追加スケール
        // outputWidth = inputWidth * scale * aspectRatio, outputHeight = inputHeight * scale
        let targetWidth = CGFloat(config.outputWidth)
        let targetHeight = CGFloat(config.outputHeight)

        let scaleX = targetWidth / croppedImage.extent.width
        let scaleY = targetHeight / croppedImage.extent.height

        guard let scaleFilter = CIFilter(name: "CILanczosScaleTransform") else {
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            return croppedImage.transformed(by: transform)
        }

        scaleFilter.setValue(croppedImage, forKey: kCIInputImageKey)
        scaleFilter.setValue(scaleY, forKey: kCIInputScaleKey)
        scaleFilter.setValue(scaleX / scaleY, forKey: kCIInputAspectRatioKey)

        return scaleFilter.outputImage
    }

    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage? {
        guard var outputImage = applyWarmthFilter(image, config: config) else {
            return nil
        }

        outputImage = applyCrop(outputImage, config: config) ?? outputImage

        return outputImage
    }

    func applyShakeEffect(_ image: CIImage, effect: ShakeEffect) -> CIImage? {
        var outputImage = image

        // 1. シフト（平行移動）
        let shiftTransform = CGAffineTransform(translationX: effect.shiftX, y: effect.shiftY)
        outputImage = outputImage.transformed(by: shiftTransform)

        // 2. 回転（中心基準）
        let rotationRadians = effect.rotation * .pi / 180.0
        let rotationTransform = CGAffineTransform(rotationAngle: rotationRadians)
        outputImage = outputImage.transformed(by: rotationTransform)

        // 3. モーションブラー
        if let motionBlurFilter = CIFilter(name: "CIMotionBlur") {
            motionBlurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            motionBlurFilter.setValue(effect.motionBlurRadius, forKey: kCIInputRadiusKey)
            motionBlurFilter.setValue(effect.motionBlurAngle * .pi / 180.0, forKey: kCIInputAngleKey)
            if let result = motionBlurFilter.outputImage {
                outputImage = result
            }
        }

        return outputImage
    }
}
