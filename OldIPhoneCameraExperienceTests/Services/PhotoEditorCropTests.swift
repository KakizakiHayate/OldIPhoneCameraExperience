//
//  PhotoEditorCropTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #49: トリミング機能テスト
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

final class PhotoEditorCropTests: XCTestCase {
    var sut: PhotoEditorService!
    var testImage: CIImage!

    override func setUp() {
        super.setUp()
        sut = PhotoEditorService()
        // 4:3（横長）テスト画像: 2592×1936
        testImage = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 2592, height: 1936))
    }

    override func tearDown() {
        sut = nil
        testImage = nil
        super.tearDown()
    }

    // MARK: - T-22.1: 画像の左上1/4をクロップ

    func test_cropRect_topLeftQuarter() {
        let rect = CGRect(x: 0, y: 968, width: 1296, height: 968)
        let result = sut.cropImage(testImage, rect: rect)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.width, 1296, accuracy: 1.0)
            XCTAssertEqual(result.extent.height, 968, accuracy: 1.0)
        }
    }

    // MARK: - T-22.2: 画像の中央50%をクロップ

    func test_cropRect_center50Percent() {
        let cropWidth = testImage.extent.width * 0.5
        let cropHeight = testImage.extent.height * 0.5
        let originX = (testImage.extent.width - cropWidth) / 2
        let originY = (testImage.extent.height - cropHeight) / 2
        let rect = CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)

        let result = sut.cropImage(testImage, rect: rect)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.width, cropWidth, accuracy: 1.0)
            XCTAssertEqual(result.extent.height, cropHeight, accuracy: 1.0)
        }
    }

    // MARK: - T-22.3: 画像サイズを超える矩形 → 画像範囲にクランプ

    func test_cropRect_exceedingBounds_isClamped() {
        let rect = CGRect(x: -100, y: -100, width: 3000, height: 2500)
        let result = sut.cropImage(testImage, rect: rect)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertLessThanOrEqual(result.extent.width, testImage.extent.width + 1)
            XCTAssertLessThanOrEqual(result.extent.height, testImage.extent.height + 1)
        }
    }

    // MARK: - T-22.4: 幅0の矩形 → nilが返る

    func test_cropRect_zeroWidth_returnsNil() {
        let rect = CGRect(x: 100, y: 100, width: 0, height: 500)
        let result = sut.cropImage(testImage, rect: rect)

        XCTAssertNil(result, "幅0の矩形ではnilが返る必要があります")
    }

    // MARK: - T-22.5: 最小サイズ未満 → 100×100にクランプ

    func test_cropRect_belowMinSize_isClamped() {
        let rect = CGRect(x: 500, y: 500, width: 50, height: 50)
        let result = sut.cropImage(testImage, rect: rect)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertGreaterThanOrEqual(result.extent.width, 100,
                                        "最小サイズ（100px）以上である必要があります")
            XCTAssertGreaterThanOrEqual(result.extent.height, 100,
                                        "最小サイズ（100px）以上である必要があります")
        }
    }

    // MARK: - T-22.6: 4:3画像を1:1でクロップ → 正方形

    func test_cropWithAspectRatio_square_producesSquare() {
        let bounds = testImage.extent
        let result = sut.cropImage(testImage, aspectRatio: .square, in: bounds)

        XCTAssertNotNil(result)
        if let result = result {
            XCTAssertEqual(result.extent.width, result.extent.height, accuracy: 1.0,
                           "1:1クロップ後は正方形である必要があります")
        }
    }

    // MARK: - T-22.7: 4:3画像を16:9でクロップ

    func test_cropWithAspectRatio_wide_produces16by9() {
        let bounds = testImage.extent
        let result = sut.cropImage(testImage, aspectRatio: .wide, in: bounds)

        XCTAssertNotNil(result)
        if let result = result {
            let ratio = result.extent.width / result.extent.height
            XCTAssertEqual(ratio, 16.0 / 9.0, accuracy: 0.01,
                           "16:9クロップ後は16:9の比率である必要があります")
        }
    }

    // MARK: - T-22.8: 4:3画像を4:3でクロップ

    func test_cropWithAspectRatio_standard_preservesRatio() {
        let bounds = testImage.extent
        let result = sut.cropImage(testImage, aspectRatio: .standard, in: bounds)

        XCTAssertNotNil(result)
        if let result = result {
            let ratio = result.extent.width / result.extent.height
            XCTAssertEqual(ratio, 4.0 / 3.0, accuracy: 0.01,
                           "4:3クロップ後は元と同じ比率である必要があります")
        }
    }

    // MARK: - T-22.9: 固定比率の精度確認

    func test_cropWithAspectRatio_ratioAccuracy() {
        let bounds = testImage.extent
        for ratio in AspectRatio.allCases {
            let result = sut.cropImage(testImage, aspectRatio: ratio, in: bounds)
            XCTAssertNotNil(result)
            if let result = result {
                let actual = result.extent.width / result.extent.height
                let expected = ratio.widthRatio / ratio.heightRatio
                XCTAssertEqual(actual, expected, accuracy: 0.01,
                               "\(ratio.displayLabel)クロップの比率が正確である必要があります")
            }
        }
    }
}

// MARK: - CropCoordinateTransformer Tests

final class CropCoordinateTransformerTests: XCTestCase {
    // MARK: - T-22.10: ビュー座標→画像座標変換（Y軸反転）

    func test_toImageRect_convertsWithYAxisFlip() {
        let transformer = CropCoordinateTransformer(
            imageSize: CGSize(width: 2592, height: 1936),
            viewSize: CGSize(width: 390, height: 520)
        )

        let viewRect = CGRect(x: 0, y: 0, width: 195, height: 260)
        let imageRect = transformer.toImageRect(viewRect)

        XCTAssertEqual(imageRect.origin.x, 0, accuracy: 1.0)
        XCTAssertEqual(imageRect.origin.y, 968, accuracy: 1.0,
                       "Y軸が反転し、下半分が選択される必要があります")
        XCTAssertEqual(imageRect.width, 1296, accuracy: 1.0)
        XCTAssertEqual(imageRect.height, 968, accuracy: 1.0)
    }

    // MARK: - T-22.11: 往復変換の一致

    func test_roundTrip_conversion_matches() {
        let transformer = CropCoordinateTransformer(
            imageSize: CGSize(width: 2592, height: 1936),
            viewSize: CGSize(width: 390, height: 520)
        )

        let originalImageRect = CGRect(x: 500, y: 300, width: 1000, height: 800)
        let viewRect = transformer.toViewRect(originalImageRect)
        let roundTrip = transformer.toImageRect(viewRect)

        XCTAssertEqual(roundTrip.origin.x, originalImageRect.origin.x, accuracy: 1.0)
        XCTAssertEqual(roundTrip.origin.y, originalImageRect.origin.y, accuracy: 1.0)
        XCTAssertEqual(roundTrip.width, originalImageRect.width, accuracy: 1.0)
        XCTAssertEqual(roundTrip.height, originalImageRect.height, accuracy: 1.0)
    }
}

// MARK: - CropRectCalculator Tests

final class CropRectCalculatorTests: XCTestCase {
    // MARK: - T-22.12: 右下角ドラッグ（自由モード）

    func test_resizeBottomRight_freeMode() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let currentRect = CGRect(x: 50, y: 50, width: 200, height: 150)
        let dragDelta = CGSize(width: 30, height: 20)

        let result = CropRectCalculator.resizeFromCorner(
            currentRect: currentRect,
            corner: .bottomRight,
            dragDelta: dragDelta,
            cropMode: .free,
            imageBounds: bounds
        )

        XCTAssertEqual(result.width, 230, accuracy: 1.0, "幅が30増加する必要があります")
        XCTAssertEqual(result.height, 170, accuracy: 1.0, "高さが20増加する必要があります")
    }

    // MARK: - T-22.13: 右下角ドラッグ（1:1固定モード）

    func test_resizeBottomRight_fixedSquareMode() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let currentRect = CGRect(x: 50, y: 50, width: 150, height: 150)
        let dragDelta = CGSize(width: 40, height: 30)

        let result = CropRectCalculator.resizeFromCorner(
            currentRect: currentRect,
            corner: .bottomRight,
            dragDelta: dragDelta,
            cropMode: .fixed(.square),
            imageBounds: bounds
        )

        XCTAssertEqual(result.width, result.height, accuracy: 1.0,
                       "1:1固定モードでは正方形を維持する必要があります")
    }

    // MARK: - T-22.14: 枠を画像端までドラッグ → はみ出さない

    func test_resize_clampsToBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let currentRect = CGRect(x: 300, y: 200, width: 80, height: 80)
        let dragDelta = CGSize(width: 200, height: 200)

        let result = CropRectCalculator.resizeFromCorner(
            currentRect: currentRect,
            corner: .bottomRight,
            dragDelta: dragDelta,
            cropMode: .free,
            imageBounds: bounds
        )

        XCTAssertLessThanOrEqual(result.maxX, bounds.maxX + 1,
                                 "枠が画像右端を超えない必要があります")
        XCTAssertLessThanOrEqual(result.maxY, bounds.maxY + 1,
                                 "枠が画像下端を超えない必要があります")
    }

    // MARK: - T-22.15: 枠内ドラッグで移動

    func test_moveRect_movesWithinBounds() {
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 300)
        let currentRect = CGRect(x: 50, y: 50, width: 100, height: 100)
        let dragDelta = CGSize(width: 20, height: 30)

        let result = CropRectCalculator.moveRect(
            currentRect: currentRect,
            dragDelta: dragDelta,
            imageBounds: bounds
        )

        XCTAssertEqual(result.origin.x, 70, accuracy: 1.0, "X方向に20移動する必要があります")
        XCTAssertEqual(result.origin.y, 80, accuracy: 1.0, "Y方向に30移動する必要があります")
        XCTAssertEqual(result.width, 100, accuracy: 1.0, "サイズは変わらない必要があります")
    }
}
