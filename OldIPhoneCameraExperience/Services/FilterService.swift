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

        // 2. 出力解像度にスケーリング（Aspect Fill + 中央クロップ）
        // 入力画像が縦向き（高さ＞幅）の場合、出力解像度の幅と高さを入れ替える
        let isPortrait = croppedImage.extent.height > croppedImage.extent.width
        let targetWidth = CGFloat(isPortrait ? config.outputHeight : config.outputWidth)
        let targetHeight = CGFloat(isPortrait ? config.outputWidth : config.outputHeight)

        let scaleX = targetWidth / croppedImage.extent.width
        let scaleY = targetHeight / croppedImage.extent.height
        let scale = max(scaleX, scaleY)

        let scaledImage: CIImage
        if let scaleFilter = CIFilter(name: "CILanczosScaleTransform") {
            scaleFilter.setValue(croppedImage, forKey: kCIInputImageKey)
            scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
            scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            scaledImage = scaleFilter.outputImage ?? croppedImage
        } else {
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            scaledImage = croppedImage.transformed(by: transform)
        }

        // 中央クロップで目的の解像度に合わせる
        let finalCropRect = CGRect(
            x: scaledImage.extent.origin.x + (scaledImage.extent.width - targetWidth) / 2.0,
            y: scaledImage.extent.origin.y + (scaledImage.extent.height - targetHeight) / 2.0,
            width: targetWidth,
            height: targetHeight
        )

        return scaledImage.cropped(to: finalCropRect)
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
        var outputImage = image

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
        outputImage = outputImage.transformed(by: combined)

        // 元の画像範囲でクロップ（白余白を除去）
        outputImage = outputImage.cropped(to: originalExtent)

        // 2. モーションブラー
        if let motionBlurFilter = CIFilter(name: "CIMotionBlur") {
            motionBlurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            motionBlurFilter.setValue(effect.motionBlurRadius, forKey: kCIInputRadiusKey)
            motionBlurFilter.setValue(effect.motionBlurAngle * .pi / 180.0, forKey: kCIInputAngleKey)
            if let result = motionBlurFilter.outputImage {
                outputImage = result
            }
        }

        // モーションブラーでもextentが拡張されるため、再度クロップ
        outputImage = outputImage.cropped(to: originalExtent)

        return outputImage
    }
}
