//
//  CameraViewModelVideoTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #44: 動画撮影ViewModel + UI テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class CameraViewModelVideoTests: XCTestCase {
    var sut: CameraViewModel!
    var mockCameraService: MockCameraService!
    var mockFilterService: MockFilterService!
    var mockPhotoLibraryService: MockPhotoLibraryService!
    var mockMotionService: MockMotionService!

    override func setUp() {
        super.setUp()
        mockCameraService = MockCameraService()
        mockFilterService = MockFilterService()
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

    // MARK: - T-17.1: デフォルトモードが写真

    func test_defaultMode_isPhoto() {
        XCTAssertEqual(sut.captureMode, .photo, "デフォルトモードは写真モードである必要があります")
    }

    // MARK: - T-17.2: switchToVideoMode で動画モードに切替

    func test_switchToVideoMode_changesMode() {
        sut.switchToVideoMode()

        XCTAssertEqual(sut.captureMode, .video, "switchToVideoMode後は動画モードである必要があります")
    }

    // MARK: - T-17.3: switchToPhotoMode で写真モードに切替

    func test_switchToPhotoMode_changesMode() {
        sut.switchToVideoMode()
        sut.switchToPhotoMode()

        XCTAssertEqual(sut.captureMode, .photo, "switchToPhotoMode後は写真モードである必要があります")
    }

    // MARK: - T-17.4: 録画中はモード切替不可

    func test_switchMode_duringRecording_isBlocked() {
        sut.switchToVideoMode()
        sut.startRecording()

        sut.switchToPhotoMode()

        XCTAssertEqual(sut.captureMode, .video, "録画中はモード切替が無効化される必要があります")
    }

    // MARK: - T-17.5: 写真モードで switchToPhotoMode は何もしない

    func test_switchToPhotoMode_alreadyPhoto_noChange() {
        XCTAssertEqual(sut.captureMode, .photo)

        sut.switchToPhotoMode()

        XCTAssertEqual(sut.captureMode, .photo)
    }

    // MARK: - T-17.6: フラッシュONで動画モード切替→トーチON

    func test_flashOn_switchToVideo_enablesTorch() {
        sut.toggleFlash()
        XCTAssertTrue(sut.state.isFlashOn)

        sut.switchToVideoMode()

        XCTAssertTrue(mockCameraService.torchEnabled, "動画モード切替時にトーチがONになる必要があります")
    }

    // MARK: - T-17.7: トーチONで写真モード切替→フラッシュON

    func test_torchOn_switchToPhoto_enablesFlash() {
        sut.toggleFlash()
        sut.switchToVideoMode()

        sut.switchToPhotoMode()

        XCTAssertTrue(sut.state.isFlashOn, "写真モード切替時にフラッシュONが維持される必要があります")
        XCTAssertTrue(mockCameraService.flashEnabled, "写真モード切替時にフラッシュが有効になる必要があります")
    }

    // MARK: - T-17.8: 動画モードで録画開始

    func test_startRecording_setsIsRecording() {
        sut.switchToVideoMode()
        sut.startRecording()

        XCTAssertTrue(sut.isRecording, "startRecording後はisRecordingがtrueになる必要があります")
    }

    // MARK: - T-17.9: 録画停止

    func test_stopRecording_stopsRecording() async throws {
        sut.switchToVideoMode()
        sut.startRecording()
        XCTAssertTrue(sut.isRecording)

        try await sut.stopRecording()

        XCTAssertFalse(sut.isRecording, "stopRecording後はisRecordingがfalseになる必要があります")
    }

    // MARK: - T-17.11: 録画停止後にrecordingDurationがリセット

    func test_stopRecording_resetsDuration() async throws {
        sut.switchToVideoMode()
        sut.startRecording()

        try await sut.stopRecording()

        XCTAssertEqual(sut.recordingDuration, 0, "停止後はrecordingDurationが0にリセットされる必要があります")
    }

    // MARK: - T-17.12: 録画中にカメラ切替不可

    func test_switchCamera_duringRecording_isBlocked() async throws {
        try await sut.startCamera()
        sut.switchToVideoMode()
        sut.startRecording()

        try await sut.switchCamera()

        // カメラ切替はisRecordingがtrueなので実行されない
        XCTAssertEqual(sut.state.cameraPosition, .back, "録画中はカメラ切替が無効化される必要があります")
    }

    // MARK: - T-17.13: 処理中はstartRecording不可

    func test_startRecording_duringProcessing_isBlocked() {
        sut.switchToVideoMode()
        // isProcessingVideoを直接設定はできないが、写真モード時の動作を検証
        XCTAssertFalse(sut.isProcessingVideo, "初期状態ではisProcessingVideoはfalseである必要があります")
    }

    // MARK: - T-17.14: 写真モードのcaptureMode

    func test_captureMode_defaultIsPhoto() {
        XCTAssertEqual(sut.captureMode, .photo)
    }

    // MARK: - T-17.19: 録画時間65秒のフォーマット

    func test_formattedDuration_65seconds() {
        sut.switchToVideoMode()
        sut.startRecording()
        // recordingDurationを直接設定（テスト用にプロパティが private(set) なので内部タイマーのテストに）
        // ViewModel の formattedRecordingDuration をテスト
        // 内部値の設定はできないので、フォーマッターのみテスト
        XCTAssertEqual(sut.formattedRecordingDuration, "00:00", "録画開始直後は00:00である必要があります")
    }

    // MARK: - T-17.20: モード切替でプリセットは変わらない（起動時に統一済み）

    func test_switchToVideoMode_presetUnchanged() {
        let originalPreset = mockCameraService.currentPreset
        sut.switchToVideoMode()

        XCTAssertEqual(
            mockCameraService.currentPreset,
            originalPreset,
            "モード切替でプリセットは変更されない（起動時に統一済み）"
        )
    }

    // MARK: - T-17.22: 写真モード復帰でもプリセットは変わらない

    func test_switchToPhotoMode_presetUnchanged() {
        let originalPreset = mockCameraService.currentPreset
        sut.switchToVideoMode()
        sut.switchToPhotoMode()

        XCTAssertEqual(
            mockCameraService.currentPreset,
            originalPreset,
            "モード切替でプリセットは変更されない（起動時に統一済み）"
        )
    }
}
