//
//  FilterService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreImage
import CoreGraphics

/// フィルター処理を提供するプロトコル
protocol FilterServiceProtocol {
    /// 暖色系フィルターを適用する
    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// 画角クロップを適用する
    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// すべてのフィルターを適用する（暖色系 → クロップ）
    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage?
}

/// フィルター処理の実装
final class FilterService: FilterServiceProtocol {

    private let context = CIContext()

    // MARK: - FilterServiceProtocol

    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage? {
        var outputImage = image

        // 1. 色温度とティントの調整
        if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
            temperatureFilter.setValue(outputImage, forKey: kCIInputImageKey)
            temperatureFilter.setValue(
                CIVector(x: config.warmth, y: config.tint),
                forKey: "inputNeutral"
            )
            if let result = temperatureFilter.outputImage {
                outputImage = result
            }
        }

        // 2. 彩度の調整
        if let saturationFilter = CIFilter(name: "CIColorControls") {
            saturationFilter.setValue(outputImage, forKey: kCIInputImageKey)
            saturationFilter.setValue(config.saturation, forKey: kCIInputSaturationKey)
            if let result = saturationFilter.outputImage {
                outputImage = result
            }
        }

        // 3. ハイライトへのオレンジティント
        if let colorMatrix = CIFilter(name: "CIColorMatrix") {
            colorMatrix.setValue(outputImage, forKey: kCIInputImageKey)
            // オレンジ系のティントを追加（赤と緑を微増）
            let tintIntensity = CGFloat(config.highlightTintIntensity)
            colorMatrix.setValue(
                CIVector(x: 1.0 + tintIntensity, y: 0, z: 0, w: 0),
                forKey: "inputRVector"
            )
            colorMatrix.setValue(
                CIVector(x: 0, y: 1.0 + tintIntensity * 0.5, z: 0, w: 0),
                forKey: "inputGVector"
            )
            if let result = colorMatrix.outputImage {
                outputImage = result
            }
        }

        return outputImage
    }

    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let inputExtent = image.extent
        let inputWidth = inputExtent.width
        let inputHeight = inputExtent.height

        // 1. クロップ率に基づいて中央部分を切り出す
        let cropRatio = CGFloat(config.cropRatio)
        let croppedWidth = inputWidth * cropRatio
        let croppedHeight = inputHeight * cropRatio

        let cropX = (inputWidth - croppedWidth) / 2
        let cropY = (inputHeight - croppedHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: croppedWidth, height: croppedHeight)

        var outputImage = image.cropped(to: cropRect)

        // 2. 出力解像度にスケーリング
        let targetWidth = CGFloat(config.outputWidth)
        let targetHeight = CGFloat(config.outputHeight)

        let scaleX = targetWidth / croppedWidth
        let scaleY = targetHeight / croppedHeight

        if let scaleFilter = CIFilter(name: "CILanczosScaleTransform") {
            scaleFilter.setValue(outputImage, forKey: kCIInputImageKey)
            scaleFilter.setValue(scaleX, forKey: kCIInputScaleKey)
            scaleFilter.setValue(1.0, forKey: kCIInputAspectRatioKey)
            if let result = scaleFilter.outputImage {
                outputImage = result
            }
        }

        // 3. アスペクト比を4:3に調整（念のため）
        let finalExtent = outputImage.extent
        let finalWidth = finalExtent.width
        let finalHeight = finalExtent.height
        let targetAspectRatio = 4.0 / 3.0
        let currentAspectRatio = finalWidth / finalHeight

        if abs(currentAspectRatio - targetAspectRatio) > 0.01 {
            // アスペクト比が異なる場合、中央部分を切り出す
            let adjustedHeight = finalWidth / targetAspectRatio
            let adjustY = (finalHeight - adjustedHeight) / 2
            let adjustRect = CGRect(x: 0, y: adjustY, width: finalWidth, height: adjustedHeight)
            outputImage = outputImage.cropped(to: adjustRect)
        }

        return outputImage
    }

    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage? {
        guard var outputImage = applyWarmthFilter(image, config: config) else {
            return nil
        }

        outputImage = applyCrop(outputImage, config: config) ?? outputImage

        return outputImage
    }
}
