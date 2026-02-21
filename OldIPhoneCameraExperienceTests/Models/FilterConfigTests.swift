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
}
