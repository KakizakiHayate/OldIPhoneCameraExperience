//
//  CameraServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

/// モックCameraService（テスト用）
final class MockCameraService: CameraServiceProtocol {
    var captureSession = AVCaptureSession()
    var isSessionRunning: Bool = false
    var flashEnabled: Bool = false
    var currentPosition: AVCaptureDevice.Position = .back

    func startSession() async throws {
        isSessionRunning = true
    }

    func stopSession() {
        isSessionRunning = false
    }

    func capturePhoto() async throws -> CIImage {
        // テスト用のダミー画像を返す
        return CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }

    func setFlash(enabled: Bool) {
        flashEnabled = enabled
    }

    func switchCamera() async throws {
        currentPosition = (currentPosition == .back) ? .front : .back
    }
}

final class CameraServiceTests: XCTestCase {
    var sut: MockCameraService!

    override func setUp() {
        super.setUp()
        sut = MockCameraService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - S-C1: startSessionでセッション開始

    func test_startSession_setsIsSessionRunningTrue() async throws {
        XCTAssertFalse(sut.isSessionRunning, "初期状態ではセッションは停止している必要があります")

        try await sut.startSession()

        XCTAssertTrue(sut.isSessionRunning, "startSession後はisSessionRunning == trueである必要があります")
    }

    // MARK: - S-C2: stopSessionでセッション停止

    func test_stopSession_setsIsSessionRunningFalse() async throws {
        try await sut.startSession()
        XCTAssertTrue(sut.isSessionRunning)

        sut.stopSession()

        XCTAssertFalse(sut.isSessionRunning, "stopSession後はisSessionRunning == falseである必要があります")
    }

    // MARK: - S-C3: setFlash(enabled: true)でフラッシュ設定

    func test_setFlash_enabledTrue_setsFlashOn() {
        sut.setFlash(enabled: true)

        XCTAssertTrue(sut.flashEnabled, "setFlash(enabled: true)でフラッシュがオンになる必要があります")
    }

    // MARK: - S-C4: setFlash(enabled: false)でオフ

    func test_setFlash_enabledFalse_setsFlashOff() {
        sut.setFlash(enabled: true)
        sut.setFlash(enabled: false)

        XCTAssertFalse(sut.flashEnabled, "setFlash(enabled: false)でフラッシュがオフになる必要があります")
    }

    // MARK: - S-C5: switchCameraでカメラ位置切替

    func test_switchCamera_togglesPosition() async throws {
        XCTAssertEqual(sut.currentPosition, .back, "初期状態では背面カメラである必要があります")

        try await sut.switchCamera()
        XCTAssertEqual(sut.currentPosition, .front, "switchCamera後は前面カメラである必要があります")

        try await sut.switchCamera()
        XCTAssertEqual(sut.currentPosition, .back, "再度switchCamera後は背面カメラに戻る必要があります")
    }

    // MARK: - S-C6: capturePhotoでCIImageが返される

    func test_capturePhoto_returnsCIImage() async throws {
        let image = try await sut.capturePhoto()

        XCTAssertNotNil(image, "capturePhotoはnilでないCIImageを返す必要があります")
        XCTAssertGreaterThan(image.extent.width, 0, "画像の幅は0より大きい必要があります")
        XCTAssertGreaterThan(image.extent.height, 0, "画像の高さは0より大きい必要があります")
    }
}
