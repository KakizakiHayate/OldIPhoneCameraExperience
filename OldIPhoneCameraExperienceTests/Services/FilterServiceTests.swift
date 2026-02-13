//
//  FilterServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

final class FilterServiceTests: XCTestCase {
    var sut: FilterService!
    var testImage: CIImage!

    override func setUp() {
        super.setUp()
        sut = FilterService()
        // テスト用の白い画像を作成（100x100）
        testImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    override func tearDown() {
        sut = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - S-F1: applyWarmthFilterにCIImageを渡すとnilでない結果が返る

    func test_applyWarmthFilter_returnsNonNilResult() {
        let result = sut.applyWarmthFilter(testImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result, "applyWarmthFilterはnilでない結果を返す必要があります")
    }

    // MARK: - S-F2: applyWarmthFilter適用後の画像サイズが入力と同じ

    func test_applyWarmthFilter_preservesImageSize() throws {
        let result = try XCTUnwrap(
            sut.applyWarmthFilter(testImage, config: FilterConfig.iPhone4)
        )

        XCTAssertEqual(
            result.extent.size.width,
            testImage.extent.size.width,
            accuracy: 1.0,
            "出力画像の幅は入力画像と同じである必要があります"
        )
        XCTAssertEqual(
            result.extent.size.height,
            testImage.extent.size.height,
            accuracy: 1.0,
            "出力画像の高さは入力画像と同じである必要があります"
        )
    }

    // MARK: - S-F3: FilterConfig.iPhone4のパラメータで正常動作

    func test_applyWarmthFilter_worksWithiPhone4Config() {
        let result = sut.applyWarmthFilter(testImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result, "iPhone 4のフィルター設定で正常に動作する必要があります")
    }

    // MARK: - S-F4: applyCropでクロップされた画像が返る

    func test_applyCrop_returnsSmallerImage() {
        // クロップ後に出力解像度(2592x1936)より大きい画像を使用
        let largeImage = CIImage(color: .white).cropped(
            to: CGRect(x: 0, y: 0, width: 4000, height: 3000)
        )
        let result = sut.applyCrop(largeImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        if let result = result {
            let inputArea = largeImage.extent.size.width * largeImage.extent.size.height
            let outputArea = result.extent.size.width * result.extent.size.height
            XCTAssertLessThan(
                outputArea,
                inputArea,
                "クロップ後の画像は元の画像より小さい必要があります"
            )
        }
    }

    // MARK: - S-F5: 出力画像のアスペクト比が4:3

    func test_applyCrop_outputAspectRatio_is4to3() {
        let result = sut.applyCrop(testImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        if let result = result {
            let aspectRatio = result.extent.size.width / result.extent.size.height
            let expected = 4.0 / 3.0
            XCTAssertEqual(
                aspectRatio,
                expected,
                accuracy: 0.01,
                "出力画像のアスペクト比は4:3である必要があります"
            )
        }
    }

    // MARK: - S-F6: 出力画像の解像度が2592x1936

    func test_applyCrop_outputResolution_is2592x1936() {
        // より大きな入力画像を使用（クロップ後に2592x1936になるように）
        let largeImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 4000, height: 3000))
        let result = sut.applyCrop(largeImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(
                result.extent.size.width,
                CGFloat(FilterConfig.iPhone4.outputWidth),
                accuracy: 1.0,
                "出力画像の幅は2592pxである必要があります"
            )
            XCTAssertEqual(
                result.extent.size.height,
                CGFloat(FilterConfig.iPhone4.outputHeight),
                accuracy: 1.0,
                "出力画像の高さは1936pxである必要があります"
            )
        }
    }

    // MARK: - S-F7: applyShakeEffectにCIImageとShakeEffectを渡すとnilでない結果が返る

    func test_applyShakeEffect_returnsNonNilResult() {
        let effect = ShakeEffect(
            shiftX: 2.0,
            shiftY: 3.0,
            rotation: 0.3,
            motionBlurRadius: 2.0,
            motionBlurAngle: 45.0
        )

        let result = sut.applyShakeEffect(testImage, effect: effect)

        XCTAssertNotNil(result, "applyShakeEffectはnilでない結果を返す必要があります")
    }

    // MARK: - S-F8: 2回applyShakeEffectを呼ぶと異なる結果が返る

    func test_applyShakeEffect_differentEffectsProduceDifferentResults() {
        let effect1 = ShakeEffect(
            shiftX: 1.0,
            shiftY: 1.0,
            rotation: 0.1,
            motionBlurRadius: 1.0,
            motionBlurAngle: 0.0
        )
        let effect2 = ShakeEffect(
            shiftX: 5.0,
            shiftY: 5.0,
            rotation: 0.5,
            motionBlurRadius: 3.0,
            motionBlurAngle: 180.0
        )

        let result1 = sut.applyShakeEffect(testImage, effect: effect1)
        let result2 = sut.applyShakeEffect(testImage, effect: effect2)

        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
        if let r1 = result1, let r2 = result2 {
            let extentsAreDifferent = r1.extent != r2.extent
            XCTAssertTrue(extentsAreDifferent, "異なるShakeEffectを適用すると異なる結果が返る必要があります")
        }
    }
}
