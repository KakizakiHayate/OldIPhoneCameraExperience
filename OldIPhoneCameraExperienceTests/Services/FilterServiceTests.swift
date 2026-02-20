//
//  FilterServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

// MARK: - MockFilterService

final class MockFilterService: FilterServiceProtocol {
    var applyWarmthFilterCalled = false
    var applyCropCalled = false
    var applyDownscaleCalled = false
    var applyFiltersCalled = false
    var applyShakeEffectCalled = false
    var applyFilterToVideoCalled = false
    var isProcessingVideo = false

    func applyWarmthFilter(_ image: CIImage, config _: FilterConfig) -> CIImage? {
        applyWarmthFilterCalled = true
        return image
    }

    func applyCrop(_ image: CIImage, config _: FilterConfig) -> CIImage? {
        applyCropCalled = true
        return image
    }

    func applyDownscale(_ image: CIImage, config _: FilterConfig) -> CIImage? {
        applyDownscaleCalled = true
        return image
    }

    func applyFilters(_ image: CIImage, config _: FilterConfig) -> CIImage? {
        applyFiltersCalled = true
        return image
    }

    func applyShakeEffect(_ image: CIImage, effect _: ShakeEffect) -> CIImage? {
        applyShakeEffectCalled = true
        return image
    }

    func applyFilterToVideo(inputURL: URL, config _: FilterConfig) async throws -> URL {
        applyFilterToVideoCalled = true
        return inputURL
    }
}

// MARK: - FilterServiceTests

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

    // MARK: - S-F5: クロップ後のアスペクト比が入力と同じ（クロップはアスペクト比を維持する）

    func test_applyCrop_preservesAspectRatio() {
        let wideImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 4000, height: 3000))
        let result = sut.applyCrop(wideImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        if let result = result {
            let inputAspect = wideImage.extent.size.width / wideImage.extent.size.height
            let outputAspect = result.extent.size.width / result.extent.size.height
            XCTAssertEqual(
                outputAspect,
                inputAspect,
                accuracy: 0.01,
                "クロップ後のアスペクト比は入力画像と同じである必要があります"
            )
        }
    }

    // MARK: - S-F6: クロップ後のサイズがcropRatio分だけ縮小されている

    func test_applyCrop_outputSizeMatchesCropRatio() {
        let largeImage = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 4000, height: 3000))
        let result = sut.applyCrop(largeImage, config: FilterConfig.iPhone4)

        XCTAssertNotNil(result)
        if let result = result {
            let expectedWidth = 4000.0 * FilterConfig.iPhone4.cropRatio
            let expectedHeight = 3000.0 * FilterConfig.iPhone4.cropRatio
            XCTAssertEqual(
                result.extent.size.width,
                CGFloat(expectedWidth),
                accuracy: 1.0,
                "出力画像の幅はcropRatio分だけ縮小される必要があります"
            )
            XCTAssertEqual(
                result.extent.size.height,
                CGFloat(expectedHeight),
                accuracy: 1.0,
                "出力画像の高さはcropRatio分だけ縮小される必要があります"
            )
        }
    }

    // MARK: - S-F-DS1: applyDownscaleで画像が5MP相当にスケーリングされる

    func test_applyDownscale_scalesToiPhone4Resolution() throws {
        // iPhone 12のカメラ出力に近い4032x3024の横長画像
        let largeImage = CIImage(color: .white).cropped(
            to: CGRect(x: 0, y: 0, width: 4032, height: 3024)
        )
        let result = try XCTUnwrap(sut.applyDownscale(largeImage, config: FilterConfig.iPhone4))

        // 横長画像なのでoutputWidth=2592, outputHeight=1936がそのまま適用
        // アスペクト比を維持するのでmin(scaleX, scaleY)で決まる
        let expectedScale = min(
            CGFloat(FilterConfig.iPhone4.outputWidth) / largeImage.extent.width,
            CGFloat(FilterConfig.iPhone4.outputHeight) / largeImage.extent.height
        )
        let expectedWidth = largeImage.extent.width * expectedScale
        let expectedHeight = largeImage.extent.height * expectedScale

        XCTAssertEqual(result.extent.size.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(result.extent.size.height, expectedHeight, accuracy: 1.0)
    }

    // MARK: - S-F-DS2: applyDownscaleで縦長画像のwidth/heightが正しく入れ替わる

    func test_applyDownscale_handlesPortraitImage() throws {
        // 縦長画像（ポートレート）
        let portraitImage = CIImage(color: .white).cropped(
            to: CGRect(x: 0, y: 0, width: 3024, height: 4032)
        )
        let result = try XCTUnwrap(sut.applyDownscale(portraitImage, config: FilterConfig.iPhone4))

        // 縦長なのでターゲットはwidth=1936, height=2592に入れ替わる
        let targetWidth: CGFloat = 1936
        let targetHeight: CGFloat = 2592
        let expectedScale = min(targetWidth / portraitImage.extent.width, targetHeight / portraitImage.extent.height)
        let expectedWidth = portraitImage.extent.width * expectedScale
        let expectedHeight = portraitImage.extent.height * expectedScale

        XCTAssertEqual(result.extent.size.width, expectedWidth, accuracy: 1.0)
        XCTAssertEqual(result.extent.size.height, expectedHeight, accuracy: 1.0)
    }

    // MARK: - S-F-DS3: 既にターゲットサイズ以下の画像はスケーリングしない

    func test_applyDownscale_skipsIfAlreadySmall() throws {
        // ターゲットより小さい画像
        let smallImage = CIImage(color: .white).cropped(
            to: CGRect(x: 0, y: 0, width: 1000, height: 800)
        )
        let result = try XCTUnwrap(sut.applyDownscale(smallImage, config: FilterConfig.iPhone4))

        XCTAssertEqual(result.extent.size.width, smallImage.extent.width, accuracy: 0.1)
        XCTAssertEqual(result.extent.size.height, smallImage.extent.height, accuracy: 0.1)
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
            // 修正後はextentが常に同じ（元の範囲に固定）なので、ピクセルデータで比較する
            let context = CIContext()
            let data1 = context.tiffRepresentation(of: r1, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
            let data2 = context.tiffRepresentation(of: r2, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
            XCTAssertNotEqual(data1, data2, "異なるShakeEffectを適用すると異なるピクセルデータが返る必要があります")
        }
    }
}
