//
//  AspectRatioTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #45: AspectRatio テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

final class AspectRatioTests: XCTestCase {
    // MARK: - T-18.1: .square のportraitRatioが1.0

    func test_square_portraitRatio_isOne() {
        XCTAssertEqual(AspectRatio.square.portraitRatio, 1.0, accuracy: 0.001,
                       "1:1のportraitRatioは1.0である必要があります")
    }

    // MARK: - T-18.2: .standard のportraitRatioが0.75

    func test_standard_portraitRatio_isThreeQuarters() {
        XCTAssertEqual(AspectRatio.standard.portraitRatio, 0.75, accuracy: 0.001,
                       "4:3のportraitRatioは0.75（3/4）である必要があります")
    }

    // MARK: - T-18.3: .wide のportraitRatioが0.5625

    func test_wide_portraitRatio_is9Over16() {
        XCTAssertEqual(AspectRatio.wide.portraitRatio, 0.5625, accuracy: 0.001,
                       "16:9のportraitRatioは0.5625（9/16）である必要があります")
    }

    // MARK: - T-18.4: 各enumの表示ラベル

    func test_displayLabels() {
        XCTAssertEqual(AspectRatio.square.displayLabel, "1:1")
        XCTAssertEqual(AspectRatio.standard.displayLabel, "4:3")
        XCTAssertEqual(AspectRatio.wide.displayLabel, "16:9")
    }

    // MARK: - T-18.5: .standard.next() → .square

    func test_standard_next_isSquare() {
        XCTAssertEqual(AspectRatio.standard.next(), .square,
                       "standardの次はsquareである必要があります")
    }

    // MARK: - T-18.6: .square.next() → .wide

    func test_square_next_isWide() {
        XCTAssertEqual(AspectRatio.square.next(), .wide,
                       "squareの次はwideである必要があります")
    }

    // MARK: - T-18.7: .wide.next() → .standard（循環）

    func test_wide_next_isStandard() {
        XCTAssertEqual(AspectRatio.wide.next(), .standard,
                       "wideの次はstandard（循環）である必要があります")
    }
}
