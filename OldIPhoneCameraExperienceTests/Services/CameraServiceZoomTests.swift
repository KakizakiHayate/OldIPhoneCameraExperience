//
//  CameraServiceZoomTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #40: ズーム基盤 — CameraService + CameraViewModel
//

@testable import OldIPhoneCameraExperience
import XCTest

final class CameraServiceZoomTests: XCTestCase {
    var sut: MockCameraService!

    override func setUp() {
        super.setUp()
        sut = MockCameraService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-13.1: setZoom(factor: 3.0) でzoomFactorが3.0に設定される

    func test_setZoom_factor3_setsZoomFactorTo3() {
        sut.setZoom(factor: 3.0)

        XCTAssertEqual(sut.currentZoomFactor, 3.0, "setZoom(factor: 3.0)でzoomFactorが3.0に設定される必要があります")
    }

    // MARK: - T-13.2: setZoom(factor: 0.5) で1.0にクランプされる

    func test_setZoom_factorBelowMin_clampsToMin() {
        sut.setZoom(factor: 0.5)

        XCTAssertEqual(sut.currentZoomFactor, CameraConfig.minZoomFactor, "下限以下の値は最小値にクランプされる必要があります")
    }

    // MARK: - T-13.3: setZoom(factor: 8.0) で5.0にクランプされる

    func test_setZoom_factorAboveMax_clampsToMax() {
        sut.setZoom(factor: 8.0)

        XCTAssertEqual(sut.currentZoomFactor, CameraConfig.maxZoomFactor, "上限以上の値は最大値にクランプされる必要があります")
    }

    // MARK: - T-13.4: カメラ切替でzoomFactorが1.0にリセットされる

    func test_switchCamera_resetsZoomFactor() async throws {
        sut.setZoom(factor: 3.0)
        XCTAssertEqual(sut.currentZoomFactor, 3.0)

        try await sut.switchCamera()

        XCTAssertEqual(sut.currentZoomFactor, CameraConfig.minZoomFactor, "カメラ切替後はzoomFactorが1.0にリセットされる必要があります")
    }

    // MARK: - T-13.5: 前面カメラのmaxが3.0の場合に5.0を指定すると3.0にクランプ

    func test_setZoom_frontCameraMaxLower_clampsToDeviceMax() {
        sut.deviceMaxZoomFactor = 3.0
        sut.setZoom(factor: 5.0)

        XCTAssertEqual(sut.currentZoomFactor, 3.0, "デバイスの最大ズーム値にクランプされる必要があります")
    }

    // MARK: - T-13.6: セッション未起動時にsetZoomを呼んでもエラーにならない

    func test_setZoom_sessionNotRunning_doesNotCrash() {
        XCTAssertFalse(sut.isSessionRunning)

        sut.setZoom(factor: 2.0)

        // クラッシュしなければ成功（MockなのでzoomFactorは更新される）
        XCTAssertEqual(sut.currentZoomFactor, 2.0)
    }
}
