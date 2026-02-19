//
//  CaptureModeTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #44: CaptureMode テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

final class CaptureModeTests: XCTestCase {
    // MARK: - CaptureMode enum

    func test_captureMode_hasPhotoCaseAndVideoCase() {
        let photo: CaptureMode = .photo
        let video: CaptureMode = .video

        XCTAssertEqual(photo, .photo)
        XCTAssertEqual(video, .video)
        XCTAssertNotEqual(photo, video)
    }

    func test_captureMode_conformsToCaseIterable() {
        XCTAssertEqual(CaptureMode.allCases.count, 2)
        XCTAssertTrue(CaptureMode.allCases.contains(.photo))
        XCTAssertTrue(CaptureMode.allCases.contains(.video))
    }
}
