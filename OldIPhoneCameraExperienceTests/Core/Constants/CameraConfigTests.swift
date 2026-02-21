//
//  CameraConfigTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
@testable import OldIPhoneCameraExperience
import XCTest

final class CameraConfigTests: XCTestCase {
    // MARK: - C-CC1: defaultPositionが背面カメラであること

    func test_defaultPosition_isBack() {
        XCTAssertEqual(
            CameraConfig.defaultPosition,
            .back,
            "defaultPositionは背面カメラ（.back）である必要があります"
        )
    }

    // MARK: - C-CC2: targetFPSが30以上であること

    func test_targetFPS_isAtLeast30() {
        XCTAssertGreaterThanOrEqual(
            CameraConfig.targetFPS,
            30,
            "targetFPSは30以上である必要があります"
        )
    }
}
