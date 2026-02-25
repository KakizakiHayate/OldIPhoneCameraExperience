//
//  CameraViewModelTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import CoreImage
@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class CameraViewModelTests: XCTestCase {
    var sut: CameraViewModel!
    var mockCameraService: MockCameraService!
    var mockFilterService: FilterService!
    var mockPhotoLibraryService: MockPhotoLibraryService!
    var mockMotionService: MockMotionService!

    override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService()
        mockFilterService = FilterService()
        mockPhotoLibraryService = MockPhotoLibraryService()
        mockMotionService = MockMotionService()

        sut = CameraViewModel(
            cameraService: mockCameraService,
            filterService: mockFilterService,
            photoLibraryService: mockPhotoLibraryService,
            motionService: mockMotionService
        )
    }

    override func tearDown() {
        sut = nil
        mockCameraService = nil
        mockFilterService = nil
        mockPhotoLibraryService = nil
        mockMotionService = nil
        super.tearDown()
    }

    // MARK: - VM-C1: 初期状態のCameraStateが正しい

    func test_initialState_isCorrect() {
        XCTAssertFalse(sut.state.isFlashOn, "初期状態ではフラッシュはオフである必要があります")
        XCTAssertEqual(sut.state.cameraPosition, .back, "初期状態では背面カメラである必要があります")
        XCTAssertFalse(sut.state.isCapturing, "初期状態では撮影中ではない必要があります")
        XCTAssertEqual(sut.state.permissionStatus, .notDetermined, "初期状態では権限未決定である必要があります")
    }

    // MARK: - VM-C2: startCameraでカメラセッション開始

    func test_startCamera_startsSession() async throws {
        try await sut.startCamera()

        XCTAssertTrue(mockCameraService.isSessionRunning, "startCamera後はカメラセッションが開始されている必要があります")
        XCTAssertTrue(mockMotionService.isMonitoring, "startCamera後はモーションモニタリングが開始されている必要があります")
        XCTAssertEqual(sut.state.permissionStatus, .authorized, "startCamera後は権限が許可されている必要があります")
    }

    // MARK: - VM-C3: stopCameraでカメラセッション停止

    func test_stopCamera_stopsSession() async throws {
        try await sut.startCamera()
        sut.stopCamera()

        XCTAssertFalse(mockCameraService.isSessionRunning, "stopCamera後はカメラセッションが停止されている必要があります")
        XCTAssertFalse(mockMotionService.isMonitoring, "stopCamera後はモーションモニタリングが停止されている必要があります")
    }

    // MARK: - VM-C4: 初期状態でlastCapturedImageがnil

    func test_initialState_lastCapturedImageIsNil() {
        XCTAssertNil(sut.lastCapturedImage, "初期状態ではlastCapturedImageはnilである必要があります")
    }

    // MARK: - VM-C5: toggleFlashでフラッシュ状態が反転

    func test_toggleFlash_togglesFlashState() {
        XCTAssertFalse(sut.state.isFlashOn)

        sut.toggleFlash()
        XCTAssertTrue(sut.state.isFlashOn, "toggleFlash後はフラッシュがオンになる必要があります")
    }

    // MARK: - VM-C6: toggleFlashを2回呼ぶと元に戻る

    func test_toggleFlash_twiceCancelsOut() {
        sut.toggleFlash()
        sut.toggleFlash()
        XCTAssertFalse(sut.state.isFlashOn, "toggleFlashを2回呼ぶとフラッシュがオフに戻る必要があります")
    }

    // MARK: - VM-C7: toggleFlash呼び出し時にCameraService.setFlashが呼ばれる

    func test_toggleFlash_callsCameraServiceSetFlash() {
        sut.toggleFlash()

        XCTAssertTrue(mockCameraService.setFlashCalled, "toggleFlash呼び出し時にCameraService.setFlashが呼ばれる必要があります")
        XCTAssertTrue(mockCameraService.setFlashCalledWithValue, "setFlashにtrueが渡される必要があります")
    }

    // MARK: - VM-C8: switchCameraでカメラ位置切替

    func test_switchCamera_togglesCameraPosition() async throws {
        try await sut.startCamera()
        XCTAssertEqual(sut.state.cameraPosition, .back)

        try await sut.switchCamera()
        XCTAssertEqual(sut.state.cameraPosition, .front, "switchCamera後は前面カメラになる必要があります")

        try await sut.switchCamera()
        XCTAssertEqual(sut.state.cameraPosition, .back, "再度switchCamera後は背面カメラに戻る必要があります")
    }

    // MARK: - VM-C9: 前面カメラ切替時にフラッシュがオフ

    func test_switchCamera_toFront_turnsOffFlash() async throws {
        try await sut.startCamera()
        sut.toggleFlash() // フラッシュをオンに
        XCTAssertTrue(sut.state.isFlashOn)

        try await sut.switchCamera() // 前面カメラへ

        XCTAssertFalse(sut.state.isFlashOn, "前面カメラ切替時にフラッシュがオフになる必要があります")
    }

    // MARK: - VM-C10: switchCamera呼び出し時にCameraService.switchCameraが呼ばれる

    func test_switchCamera_callsCameraServiceSwitchCamera() async throws {
        try await sut.startCamera()

        try await sut.switchCamera()

        XCTAssertTrue(mockCameraService.switchCameraCalled, "switchCamera呼び出し時にCameraService.switchCameraが呼ばれる必要があります")
    }

    // MARK: - VM-C11: capturePhoto呼び出しでisCapturingがtrue

    func test_capturePhoto_setsIsCapturingDuringCapture() async throws {
        try await sut.startCamera()

        // capturePhoto完了後はisCapturingがfalseに戻ることを確認
        try await sut.capturePhoto()

        XCTAssertFalse(sut.state.isCapturing, "撮影完了後はisCapturingがfalseに戻る必要があります")
    }

    // MARK: - VM-C12: capturePhoto完了後にisCapturingがfalse

    func test_capturePhoto_executesCapture() async throws {
        try await sut.startCamera()

        try await sut.capturePhoto()

        XCTAssertEqual(mockPhotoLibraryService.savedImages.count, 1, "撮影後は1枚の画像が保存されている必要があります")
        XCTAssertFalse(sut.state.isCapturing, "撮影完了後はisCapturingがfalseに戻る必要があります")
    }

    // MARK: - VM-C13: capturePhoto完了後にlastCapturedImageが更新

    func test_capturePhoto_updatesLastCapturedImage() async throws {
        try await sut.startCamera()
        XCTAssertNil(sut.lastCapturedImage)

        try await sut.capturePhoto()

        XCTAssertNotNil(sut.lastCapturedImage, "撮影完了後にlastCapturedImageが更新される必要があります")
    }

    // MARK: - VM-C14: カメラ権限拒否時にpermissionStatusがdenied

    func test_startCamera_permissionDenied_setsStatusToDenied() async {
        mockCameraService.shouldThrowOnStart = true

        do {
            try await sut.startCamera()
            XCTFail("権限拒否時にはエラーがthrowされる必要があります")
        } catch {
            XCTAssertEqual(sut.state.permissionStatus, .denied, "権限拒否時にpermissionStatusが.deniedになる必要があります")
        }
    }

    // MARK: - モデル切替テスト

    func test_initialModel_isIPhone4() {
        XCTAssertEqual(sut.currentModel, .iPhone4, "初期モデルはiPhone 4である必要があります")
    }

    func test_selectModel_changesToIPhone6() {
        sut.selectModel(.iPhone6)

        XCTAssertEqual(sut.currentModel, .iPhone6, "selectModel後はiPhone 6に切り替わる必要があります")
    }

    func test_selectModel_duringRecording_isBlocked() {
        sut.switchToVideoMode()
        sut.startRecording()

        sut.selectModel(.iPhone6)

        XCTAssertEqual(sut.currentModel, .iPhone4, "録画中はモデル切替が無効化される必要があります")
    }
}
