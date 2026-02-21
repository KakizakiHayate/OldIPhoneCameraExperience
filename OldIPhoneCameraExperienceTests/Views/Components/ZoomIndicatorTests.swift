//
//  ZoomIndicatorTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #41: ズームUI — インジケーター表示テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

final class ZoomIndicatorTests: XCTestCase {
    // MARK: - T-14.8: ズーム操作を開始するとインジケーターが表示される

    func test_zoomIndicator_isVisibleWhenShown() {
        let indicator = ZoomIndicator(zoomFactor: 2.0, isVisible: true)

        XCTAssertTrue(indicator.isVisible, "ズーム操作中はインジケーターが表示される必要があります")
    }

    // MARK: - T-14.10: zoomFactorが2.5の時のインジケーター表示

    func test_zoomIndicator_formatsZoomFactor_2_5() {
        let indicator = ZoomIndicator(zoomFactor: 2.5, isVisible: true)

        XCTAssertEqual(
            indicator.formattedZoom,
            "2.5x",
            "zoomFactor 2.5 は '2.5x' と表示される必要があります"
        )
    }

    // MARK: - T-14.12: zoomFactorが1.0の時のインジケーター表示

    func test_zoomIndicator_formatsZoomFactor_1_0() {
        let indicator = ZoomIndicator(zoomFactor: 1.0, isVisible: true)

        XCTAssertEqual(
            indicator.formattedZoom,
            "1.0x",
            "zoomFactor 1.0 は '1.0x' と表示される必要があります"
        )
    }

    // MARK: - T-14.10b: zoomFactorが5.0の時のインジケーター表示

    func test_zoomIndicator_formatsZoomFactor_5_0() {
        let indicator = ZoomIndicator(zoomFactor: 5.0, isVisible: true)

        XCTAssertEqual(
            indicator.formattedZoom,
            "5.0x",
            "zoomFactor 5.0 は '5.0x' と表示される必要があります"
        )
    }

    // MARK: - T-14.9: インジケーターが非表示状態

    func test_zoomIndicator_isHiddenWhenNotVisible() {
        let indicator = ZoomIndicator(zoomFactor: 2.0, isVisible: false)

        XCTAssertFalse(indicator.isVisible, "非表示状態ではisVisibleがfalseである必要があります")
    }
}
