//
//  CameraStateTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import XCTest
@testable import OldIPhoneCameraExperience

final class CameraStateTests: XCTestCase {

    // MARK: - M-CS1: デフォルト値でCameraStateを生成する
    func test_defaultValues() {
        let state = CameraState()

        XCTAssertFalse(state.isFlashOn, "デフォルトではフラッシュはオフである必要があります")
        XCTAssertEqual(state.cameraPosition, .back, "デフォルトでは背面カメラである必要があります")
        XCTAssertFalse(state.isCapturing, "デフォルトでは撮影中ではない必要があります")
        XCTAssertEqual(state.permissionStatus, .notDetermined, "デフォルトでは権限未決定である必要があります")
    }

    // MARK: - M-CS2: フラッシュオンの状態を生成する
    func test_flashOn() {
        let state = CameraState(isFlashOn: true)

        XCTAssertTrue(state.isFlashOn, "フラッシュがオンである必要があります")
    }

    // MARK: - M-CS3: 前面カメラの状態を生成する
    func test_frontCamera() {
        let state = CameraState(cameraPosition: .front)

        XCTAssertEqual(state.cameraPosition, .front, "前面カメラである必要があります")
    }

    // MARK: - M-CS4: CameraPositionのcase数が2であること
    func test_cameraPosition_hasTwoCases() {
        let allCases: [CameraPosition] = [.front, .back]

        XCTAssertEqual(allCases.count, 2, "CameraPositionは2つのケース（front, back）を持つ必要があります")
    }

    // MARK: - M-CS5: PermissionStatusのcase数が3であること
    func test_permissionStatus_hasThreeCases() {
        let allCases: [PermissionStatus] = [.notDetermined, .authorized, .denied]

        XCTAssertEqual(allCases.count, 3, "PermissionStatusは3つのケース（notDetermined, authorized, denied）を持つ必要があります")
    }
}
