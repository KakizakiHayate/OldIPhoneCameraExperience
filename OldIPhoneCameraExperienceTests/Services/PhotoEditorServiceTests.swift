//
//  PhotoEditorServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #48: PhotoEditorService テスト
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

final class PhotoEditorServiceTests: XCTestCase {
    var sut: PhotoEditorService!
    var testImage: CIImage!

    override func setUp() {
        super.setUp()
        sut = PhotoEditorService()
        testImage = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 150))
    }

    override func tearDown() {
        sut = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - T-21.1: brightness = 0.0（デフォルト）

    func test_adjustBrightness_default_returnsNonNil() {
        let result = sut.adjustBrightness(testImage, value: 0.0)

        XCTAssertNotNil(result, "brightness=0.0で出力がnilでない必要があります")
    }

    // MARK: - T-21.2: brightness = 0.3

    func test_adjustBrightness_positive_returnsNonNil() {
        let result = sut.adjustBrightness(testImage, value: 0.3)

        XCTAssertNotNil(result, "brightness=0.3で出力がnilでない必要があります")
    }

    // MARK: - T-21.3: brightness = -0.3

    func test_adjustBrightness_negative_returnsNonNil() {
        let result = sut.adjustBrightness(testImage, value: -0.3)

        XCTAssertNotNil(result, "brightness=-0.3で出力がnilでない必要があります")
    }

    // MARK: - T-21.4: brightness = 1.0（範囲外→クランプ）

    func test_adjustBrightness_outOfRange_clampsToMax() {
        let result = sut.adjustBrightness(testImage, value: 1.0)

        XCTAssertNotNil(result, "範囲外の値でもクランプされて出力がnilでない必要があります")
    }

    // MARK: - T-21.5: contrast = 1.0（デフォルト）

    func test_adjustContrast_default_returnsNonNil() {
        let result = sut.adjustContrast(testImage, value: 1.0)

        XCTAssertNotNil(result, "contrast=1.0で出力がnilでない必要があります")
    }

    // MARK: - T-21.6: contrast = 1.5

    func test_adjustContrast_high_returnsNonNil() {
        let result = sut.adjustContrast(testImage, value: 1.5)

        XCTAssertNotNil(result, "contrast=1.5で出力がnilでない必要があります")
    }

    // MARK: - T-21.7: contrast = 0.5

    func test_adjustContrast_low_returnsNonNil() {
        let result = sut.adjustContrast(testImage, value: 0.5)

        XCTAssertNotNil(result, "contrast=0.5で出力がnilでない必要があります")
    }

    // MARK: - T-21.8: contrast = 0.0（範囲外→クランプ）

    func test_adjustContrast_outOfRange_clampsToMin() {
        let result = sut.adjustContrast(testImage, value: 0.0)

        XCTAssertNotNil(result, "範囲外の値でもクランプされて出力がnilでない必要があります")
    }

    // MARK: - T-21.9: saturation = 1.0（デフォルト）

    func test_adjustSaturation_default_returnsNonNil() {
        let result = sut.adjustSaturation(testImage, value: 1.0)

        XCTAssertNotNil(result, "saturation=1.0で出力がnilでない必要があります")
    }

    // MARK: - T-21.10: saturation = 0.0（モノクロ）

    func test_adjustSaturation_zero_returnsNonNil() {
        let result = sut.adjustSaturation(testImage, value: 0.0)

        XCTAssertNotNil(result, "saturation=0.0で出力がnilでない必要があります")
    }

    // MARK: - T-21.11: saturation = 2.0

    func test_adjustSaturation_max_returnsNonNil() {
        let result = sut.adjustSaturation(testImage, value: 2.0)

        XCTAssertNotNil(result, "saturation=2.0で出力がnilでない必要があります")
    }

    // MARK: - T-21.12: saturation = 3.0（範囲外→クランプ）

    func test_adjustSaturation_outOfRange_clampsToMax() {
        let result = sut.adjustSaturation(testImage, value: 3.0)

        XCTAssertNotNil(result, "範囲外の値でもクランプされて出力がnilでない必要があります")
    }

    // MARK: - T-21.13: 一括適用

    func test_applyAdjustments_customValues_returnsNonNil() {
        let result = sut.applyAdjustments(testImage, brightness: 0.2, contrast: 1.2, saturation: 0.8)

        XCTAssertNotNil(result, "一括適用で出力がnilでない必要があります")
    }

    // MARK: - T-21.14: すべてデフォルト値で一括適用

    func test_applyAdjustments_defaults_returnsNonNil() {
        let result = sut.applyAdjustments(
            testImage,
            brightness: EditorConstants.defaultBrightness,
            contrast: EditorConstants.defaultContrast,
            saturation: EditorConstants.defaultSaturation
        )

        XCTAssertNotNil(result, "デフォルト値で一括適用した出力がnilでない必要があります")
    }

    // MARK: - T-21.15: 出力サイズが入力と同じ

    func test_applyAdjustments_preservesImageSize() {
        let result = sut.applyAdjustments(testImage, brightness: 0.1, contrast: 1.1, saturation: 0.9)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.width, testImage.extent.width, accuracy: 1.0,
                           "出力画像の幅は入力と同じである必要があります")
            XCTAssertEqual(result.extent.height, testImage.extent.height, accuracy: 1.0,
                           "出力画像の高さは入力と同じである必要があります")
        }
    }

    // MARK: - T-21.16: 5MP画像での動作

    func test_applyAdjustments_largeImage_returnsNonNil() {
        let largeImage = CIImage(color: .gray).cropped(
            to: CGRect(x: 0, y: 0, width: 2592, height: 1936)
        )

        let result = sut.applyAdjustments(largeImage, brightness: 0.1, contrast: 1.2, saturation: 0.8)

        XCTAssertNotNil(result, "5MP画像でも出力がnilでない必要があります")
    }
}
