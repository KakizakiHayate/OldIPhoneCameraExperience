//
//  UIConstantsTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import XCTest
@testable import OldIPhoneCameraExperience

final class UIConstantsTests: XCTestCase {

    // MARK: - C-UI1: shutterButtonSizeが正の値であること
    func test_shutterButtonSize_isPositiveValue() {
        XCTAssertGreaterThan(
            UIConstants.shutterButtonSize,
            0,
            "shutterButtonSizeは正の値である必要があります"
        )
    }

    // MARK: - C-UI2: irisCloseDurationがirisOpenDurationより短いこと
    func test_irisCloseDuration_isShorterThanOpenDuration() {
        XCTAssertLessThan(
            UIConstants.irisCloseDuration,
            UIConstants.irisOpenDuration,
            "irisCloseDurationはirisOpenDurationより短い必要があります"
        )
    }
}
