//
//  FilterParametersTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import XCTest

final class FilterParametersTests: XCTestCase {
    // MARK: - C-FP1: warmthShiftが正の値であること（暖色方向）

    func test_warmthShift_isPositiveValue() {
        XCTAssertGreaterThan(
            FilterParameters.warmthShift,
            0,
            "warmthShiftは正の値である必要があります（暖色方向へのシフト）"
        )
    }

    // MARK: - C-FP2: cropRatioが0〜1の範囲であること

    func test_cropRatio_isWithinZeroToOneRange() {
        XCTAssertGreaterThan(
            FilterParameters.cropRatio,
            0,
            "cropRatioは0より大きい必要があります"
        )
        XCTAssertLessThan(
            FilterParameters.cropRatio,
            1,
            "cropRatioは1より小さい必要があります"
        )
    }

    // MARK: - C-FP3: shakeShiftRangeの下限が上限より小さいこと

    func test_shakeShiftRange_lowerBoundIsLessThanUpperBound() {
        XCTAssertLessThan(
            FilterParameters.shakeShiftRange.lowerBound,
            FilterParameters.shakeShiftRange.upperBound,
            "shakeShiftRangeの下限は上限より小さい必要があります"
        )
    }
}
