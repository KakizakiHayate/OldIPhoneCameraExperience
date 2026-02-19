//
//  FilterServiceAspectRatioTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #45: アスペクト比クロップ テスト
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

final class FilterServiceAspectRatioTests: XCTestCase {
    var sut: FilterService!

    override func setUp() {
        super.setUp()
        sut = FilterService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// 3:4（ポートレート）のテスト画像を作成
    private func createPortraitImage() -> CIImage {
        CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 3000, height: 4000))
    }

    // MARK: - T-18.8: 4:3画像を1:1にクロップ → 正方形

    func test_cropToSquare_producesSquareImage() {
        let image = createPortraitImage()
        let result = sut.applyCropForAspectRatio(image, aspectRatio: .square)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.width, result.extent.height, accuracy: 1.0,
                           "1:1クロップ後は正方形になる必要があります")
        }
    }

    // MARK: - T-18.9: 4:3画像を16:9にクロップ → 9:16（縦持ち）

    func test_cropToWide_produces9by16PortraitImage() {
        let image = createPortraitImage()
        let result = sut.applyCropForAspectRatio(image, aspectRatio: .wide)

        XCTAssertNotNil(result)
        if let result = result {
            let ratio = result.extent.width / result.extent.height
            XCTAssertEqual(ratio, 9.0 / 16.0, accuracy: 0.01,
                           "16:9クロップ後は9:16（縦持ち）になる必要があります")
        }
    }

    // MARK: - T-18.10: 4:3画像を4:3にクロップ → 元と同じアスペクト比

    func test_cropToStandard_maintainsOriginalAspectRatio() {
        let image = createPortraitImage()
        let result = sut.applyCropForAspectRatio(image, aspectRatio: .standard)

        XCTAssertNotNil(result)
        if let result = result {
            let ratio = result.extent.width / result.extent.height
            XCTAssertEqual(ratio, 3.0 / 4.0, accuracy: 0.01,
                           "4:3クロップは元のアスペクト比を維持する必要があります")
        }
    }

    // MARK: - T-18.11: クロップが中央基準

    func test_cropIsCenterBased() {
        let image = createPortraitImage()
        let result = sut.applyCropForAspectRatio(image, aspectRatio: .square)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.midX, image.extent.midX, accuracy: 1.0,
                           "クロップはX方向で中央基準である必要があります")
            XCTAssertEqual(result.extent.midY, image.extent.midY, accuracy: 1.0,
                           "クロップはY方向で中央基準である必要があります")
        }
    }

    // MARK: - T-18.12: 1:1クロップ後の出力解像度が1936×1936

    func test_squareCropAndDownscale_outputResolution() {
        let image = createPortraitImage()
        let config = FilterConfig(
            warmth: FilterConfig.iPhone4.warmth,
            tint: FilterConfig.iPhone4.tint,
            saturation: FilterConfig.iPhone4.saturation,
            highlightTintIntensity: FilterConfig.iPhone4.highlightTintIntensity,
            cropRatio: FilterConfig.iPhone4.cropRatio,
            aspectRatio: .square
        )

        let result = sut.applyFilters(image, config: config)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(Int(result.extent.width), 1936,
                           "1:1の出力幅は1936pxである必要があります")
            XCTAssertEqual(Int(result.extent.height), 1936,
                           "1:1の出力高さは1936pxである必要があります")
        }
    }

    // MARK: - T-18.13: 16:9クロップ後の出力解像度が1458×2592（縦持ち）

    func test_wideCropAndDownscale_outputResolution() {
        let image = createPortraitImage()
        let config = FilterConfig(
            warmth: FilterConfig.iPhone4.warmth,
            tint: FilterConfig.iPhone4.tint,
            saturation: FilterConfig.iPhone4.saturation,
            highlightTintIntensity: FilterConfig.iPhone4.highlightTintIntensity,
            cropRatio: FilterConfig.iPhone4.cropRatio,
            aspectRatio: .wide
        )

        let result = sut.applyFilters(image, config: config)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(Int(result.extent.width), 1458,
                           "16:9の出力幅（縦持ち）は1458pxである必要があります")
            XCTAssertEqual(Int(result.extent.height), 2592,
                           "16:9の出力高さ（縦持ち）は2592pxである必要があります")
        }
    }
}
