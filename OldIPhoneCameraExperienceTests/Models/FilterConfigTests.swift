//
//  FilterConfigTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import XCTest

final class FilterConfigTests: XCTestCase {
    // MARK: - M-FC1: iPhone 4プリセットの色温度が暖色方向であること

    func test_iPhone4_warmth_isPositive() {
        XCTAssertGreaterThan(
            FilterConfig.iPhone4.warmth,
            0,
            "iPhone 4の色温度は暖色方向（正の値）である必要があります"
        )
    }

    // MARK: - M-FC2: iPhone 4プリセットの彩度が標準より低いこと

    func test_iPhone4_saturation_isLessThanOne() {
        XCTAssertGreaterThan(
            FilterConfig.iPhone4.saturation,
            0,
            "彩度は0より大きい必要があります"
        )
        XCTAssertLessThan(
            FilterConfig.iPhone4.saturation,
            1.0,
            "iPhone 4の彩度は標準（1.0）より低い必要があります"
        )
    }

    // MARK: - M-FC3: iPhone 4プリセットの出力解像度が5MP相当であること

    func test_iPhone4_resolution_is5MP() {
        let width = FilterConfig.iPhone4.outputWidth
        let height = FilterConfig.iPhone4.outputHeight

        XCTAssertEqual(width, 2592, "幅は2592pxである必要があります")
        XCTAssertEqual(height, 1936, "高さは1936pxである必要があります")

        let megapixels = Double(width * height) / 1_000_000
        XCTAssertEqual(megapixels, 5.0, accuracy: 0.1, "解像度は約5MP（500万画素）である必要があります")
    }

    // MARK: - M-FC4: iPhone 4プリセットのクロップ率が0〜1の範囲であること

    func test_iPhone4_cropRatio_isWithinRange() {
        XCTAssertGreaterThan(
            FilterConfig.iPhone4.cropRatio,
            0,
            "クロップ率は0より大きい必要があります"
        )
        XCTAssertLessThan(
            FilterConfig.iPhone4.cropRatio,
            1,
            "クロップ率は1より小さい必要があります"
        )
    }

    // MARK: - M-FC5: iPhone 4プリセットのアスペクト比が4:3であること

    func test_iPhone4_aspectRatio_is4to3() {
        let width = Double(FilterConfig.iPhone4.outputWidth)
        let height = Double(FilterConfig.iPhone4.outputHeight)
        let aspectRatio = width / height
        let expected = 4.0 / 3.0

        XCTAssertEqual(
            aspectRatio,
            expected,
            accuracy: 0.01,
            "アスペクト比は4:3である必要があります"
        )
    }

    // MARK: - iPhone 6 プリセットテスト

    func test_iPhone6_warmth_isLessThanIPhone4() {
        XCTAssertGreaterThan(
            FilterConfig.iPhone6.warmth,
            0,
            "iPhone 6の色温度は暖色方向（正の値）である必要があります"
        )
        XCTAssertLessThan(
            FilterConfig.iPhone6.warmth,
            FilterConfig.iPhone4.warmth,
            "iPhone 6の色温度はiPhone 4より低い（より自然）必要があります"
        )
    }

    func test_iPhone6_saturation_isHigherThanIPhone4() {
        XCTAssertGreaterThan(
            FilterConfig.iPhone6.saturation,
            FilterConfig.iPhone4.saturation,
            "iPhone 6の彩度はiPhone 4より高い必要があります"
        )
        XCTAssertLessThan(
            FilterConfig.iPhone6.saturation,
            1.0,
            "iPhone 6の彩度は標準（1.0）より低い必要があります"
        )
    }

    func test_iPhone6_resolution_is8MP() {
        let width = FilterConfig.iPhone6.outputWidth
        let height = FilterConfig.iPhone6.outputHeight

        XCTAssertEqual(width, 3264, "幅は3264pxである必要があります")
        XCTAssertEqual(height, 2448, "高さは2448pxである必要があります")

        let megapixels = Double(width * height) / 1_000_000
        XCTAssertEqual(megapixels, 8.0, accuracy: 0.1, "解像度は約8MP（800万画素）である必要があります")
    }

    func test_iPhone6_cropRatio_isWithinRange() {
        XCTAssertGreaterThan(FilterConfig.iPhone6.cropRatio, 0)
        XCTAssertLessThan(FilterConfig.iPhone6.cropRatio, 1)
        XCTAssertGreaterThan(
            FilterConfig.iPhone6.cropRatio,
            FilterConfig.iPhone4.cropRatio,
            "iPhone 6のクロップ率はiPhone 4より大きい（より広角）必要があります"
        )
    }

    func test_iPhone6_shake_isSmallerThanIPhone4() {
        let ip6 = FilterConfig.iPhone6
        let ip4 = FilterConfig.iPhone4

        XCTAssertLessThan(
            ip6.shakeShiftRange.upperBound,
            ip4.shakeShiftRange.upperBound,
            "iPhone 6の手ぶれシフト範囲はiPhone 4より小さい必要があります"
        )
        XCTAssertLessThan(
            ip6.motionBlurRadiusRange.upperBound,
            ip4.motionBlurRadiusRange.upperBound,
            "iPhone 6のモーションブラー範囲はiPhone 4より小さい必要があります"
        )
    }

    func test_iPhone6_outputResolution_forSquare() {
        let config = FilterConfig(
            warmth: 500, tint: 5, saturation: 0.95,
            highlightTintIntensity: 0.05, cropRatio: 0.87,
            aspectRatio: .square,
            baseWidth: 3264, baseHeight: 2448
        )
        XCTAssertEqual(config.outputWidth, 2448)
        XCTAssertEqual(config.outputHeight, 2448)
    }

    func test_iPhone6_outputResolution_forWide() {
        let config = FilterConfig(
            warmth: 500, tint: 5, saturation: 0.95,
            highlightTintIntensity: 0.05, cropRatio: 0.87,
            aspectRatio: .wide,
            baseWidth: 3264, baseHeight: 2448
        )
        XCTAssertEqual(config.outputWidth, 3264)
        XCTAssertEqual(config.outputHeight, 3264 * 9 / 16)
    }
}
