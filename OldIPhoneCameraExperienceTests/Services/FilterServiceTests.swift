//
//  FilterServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import XCTest
import CoreImage
@testable import OldIPhoneCameraExperience

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
    func test_applyWarmthFilter_preservesImageSize() {
        let result = sut.applyWarmthFilter(testImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        XCTAssertEqual(
            result?.extent.size.width,
            testImage.extent.size.width,
            accuracy: 1.0,
            "出力画像の幅は入力画像と同じである必要があります"
        )
        XCTAssertEqual(
            result?.extent.size.height,
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
    func test_applyCrop_returnsSmaller Image() {
        let result = sut.applyCrop(testImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        // クロップ後の画像は元の画像より小さいはず
        if let result = result {
            let inputArea = testImage.extent.size.width * testImage.extent.size.height
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
}
