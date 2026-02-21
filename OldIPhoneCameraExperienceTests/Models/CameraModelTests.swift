//
//  CameraModelTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import XCTest

final class CameraModelTests: XCTestCase {
    // MARK: - M-CM1: iPhone 4プリセットのnameが正しいこと

    func test_iPhone4_name() {
        XCTAssertEqual(
            CameraModel.iPhone4.name,
            "iPhone 4",
            "iPhone 4プリセットのnameは\"iPhone 4\"である必要があります"
        )
    }

    // MARK: - M-CM2: iPhone 4プリセットがisFree == trueであること

    func test_iPhone4_isFree() {
        XCTAssertTrue(
            CameraModel.iPhone4.isFree,
            "iPhone 4プリセットはisFree == trueである必要があります（MVP無料機種）"
        )
    }

    // MARK: - M-CM3: iPhone 4のfilterConfigがFilterConfig.iPhone4と一致すること

    func test_iPhone4_filterConfig_matchesPreset() {
        XCTAssertEqual(
            CameraModel.iPhone4.filterConfig,
            FilterConfig.iPhone4,
            "iPhone 4のfilterConfigはFilterConfig.iPhone4と一致する必要があります"
        )
    }
}
