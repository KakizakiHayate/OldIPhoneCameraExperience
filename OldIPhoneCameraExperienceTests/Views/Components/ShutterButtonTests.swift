//
//  ShutterButtonTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import XCTest

final class ShutterButtonTests: XCTestCase {
    // MARK: - V-SB1: isCapturing == falseで通常状態のShutterButtonが生成できること

    func test_shutterButton_normalState_canBeCreated() {
        let button = ShutterButton(action: {}, isCapturing: false)

        XCTAssertFalse(button.isCapturing, "通常状態ではisCapturingがfalseである必要があります")
    }

    // MARK: - V-SB2: isCapturing == trueで無効化状態のShutterButtonが生成できること

    func test_shutterButton_capturingState_canBeCreated() {
        let button = ShutterButton(action: {}, isCapturing: true)

        XCTAssertTrue(button.isCapturing, "撮影中状態ではisCapturingがtrueである必要があります")
    }

    // MARK: - V-SB3: actionクロージャが設定されていること

    func test_shutterButton_actionClosureIsSet() {
        var actionCalled = false
        let button = ShutterButton(action: {
            actionCalled = true
        }, isCapturing: false)

        button.action()

        XCTAssertTrue(actionCalled, "actionクロージャが呼ばれる必要があります")
    }

    // MARK: - T-17.14: 写真モードのシャッターボタン

    func test_shutterButton_photoMode_defaultCaptureMode() {
        let button = ShutterButton(action: {}, isCapturing: false)

        XCTAssertEqual(button.captureMode, .photo, "デフォルトは写真モードである必要があります")
    }

    // MARK: - T-17.15: 動画モードのシャッターボタン

    func test_shutterButton_videoMode_canBeCreated() {
        let button = ShutterButton(action: {}, isCapturing: false, captureMode: .video)

        XCTAssertEqual(button.captureMode, .video, "動画モードが設定される必要があります")
        XCTAssertFalse(button.isRecording, "初期状態では録画中でない必要があります")
    }

    // MARK: - T-17.16: 録画中のシャッターボタン

    func test_shutterButton_recording_canBeCreated() {
        let button = ShutterButton(
            action: {}, isCapturing: false,
            captureMode: .video, isRecording: true
        )

        XCTAssertTrue(button.isRecording, "録画中状態が設定される必要があります")
    }
}
