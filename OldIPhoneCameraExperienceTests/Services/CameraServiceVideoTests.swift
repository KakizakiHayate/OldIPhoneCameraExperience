//
//  CameraServiceVideoTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #42: 動画撮影基盤 — CameraService拡張テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

final class CameraServiceVideoTests: XCTestCase {
    var sut: MockCameraService!

    override func setUp() {
        super.setUp()
        sut = MockCameraService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-15.1: startRecording() で録画開始

    func test_startRecording_setsIsRecordingTrue() {
        XCTAssertFalse(sut.isRecording, "初期状態ではisRecordingはfalse")

        sut.startRecording()

        XCTAssertTrue(sut.isRecording, "startRecording後はisRecordingがtrueになる必要があります")
    }

    // MARK: - T-15.2: stopRecording() で録画停止、URLが返される

    func test_stopRecording_returnsURL() async throws {
        sut.startRecording()

        let url = try await sut.stopRecording()

        XCTAssertFalse(sut.isRecording, "stopRecording後はisRecordingがfalseになる必要があります")
        XCTAssertTrue(url.pathExtension == "mov", "動画ファイルはMOV形式である必要があります")
    }

    // MARK: - T-15.3: 録画中にstopRecording()で正常停止

    func test_stopRecording_duringRecording_stopsNormally() async throws {
        sut.startRecording()
        XCTAssertTrue(sut.isRecording)

        let url = try await sut.stopRecording()

        XCTAssertFalse(sut.isRecording)
        XCTAssertNotNil(url)
    }

    // MARK: - T-15.4: 録画していない時にstopRecording()はエラー

    func test_stopRecording_whenNotRecording_throws() async {
        do {
            _ = try await sut.stopRecording()
            XCTFail("録画していない時にstopRecordingはエラーをスローする必要があります")
        } catch {
            XCTAssertTrue(error is CameraError, "CameraErrorがスローされる必要があります")
        }
    }

    // MARK: - T-15.5: 動画解像度定数が720pである

    func test_videoPreset_is720p() {
        XCTAssertEqual(
            CameraConfig.videoPreset,
            .hd1280x720,
            "動画プリセットは720pである必要があります"
        )
    }

    // MARK: - T-15.6: 動画ファイル形式がMOV

    func test_videoFileExtension_isMov() async throws {
        sut.startRecording()
        let url = try await sut.stopRecording()

        XCTAssertEqual(url.pathExtension, "mov", "動画ファイルはMOV形式である必要があります")
    }

    // MARK: - T-15.7: setTorch(enabled: true) でトーチ点灯

    func test_setTorch_enabledTrue_turnsTorchOn() {
        sut.setTorch(enabled: true)

        XCTAssertTrue(sut.torchEnabled, "setTorch(enabled: true)でトーチがオンになる必要があります")
    }

    // MARK: - T-15.8: setTorch(enabled: false) でトーチ消灯

    func test_setTorch_enabledFalse_turnsTorchOff() {
        sut.setTorch(enabled: true)
        sut.setTorch(enabled: false)

        XCTAssertFalse(sut.torchEnabled, "setTorch(enabled: false)でトーチがオフになる必要があります")
    }

    // MARK: - T-15.9: 前面カメラ時はトーチが点灯しない

    func test_setTorch_frontCamera_doesNotEnableTorch() async throws {
        try await sut.switchCamera() // 前面カメラに切替
        XCTAssertEqual(sut.currentPosition, .front)

        sut.setTorch(enabled: true)

        XCTAssertFalse(sut.torchEnabled, "前面カメラではトーチが点灯しない必要があります")
    }

    // MARK: - T-15.10: 録画終了時にトーチが自動オフ

    func test_stopRecording_turnsTorchOff() async throws {
        sut.setTorch(enabled: true)
        XCTAssertTrue(sut.torchEnabled)

        sut.startRecording()
        _ = try await sut.stopRecording()

        XCTAssertFalse(sut.torchEnabled, "録画終了時にトーチが自動オフになる必要があります")
    }

    // MARK: - T-15.11: トーチONで前面→背面に戻してもOFFのまま

    func test_torch_afterCameraSwitch_remainsOff() async throws {
        sut.setTorch(enabled: true)
        XCTAssertTrue(sut.torchEnabled)

        try await sut.switchCamera() // 前面カメラへ
        try await sut.switchCamera() // 背面カメラへ戻る

        XCTAssertFalse(sut.torchEnabled, "カメラ切替後はトーチがOFFになる必要があります")
    }

    // MARK: - T-15.12: マイクパーミッション許可時の録画

    func test_recording_withMicPermission_recordsWithAudio() {
        sut.micPermissionGranted = true
        sut.startRecording()

        XCTAssertTrue(sut.isRecording)
        XCTAssertTrue(sut.isAudioEnabled, "マイク許可時は音声録音が有効である必要があります")
    }

    // MARK: - T-15.13: マイクパーミッション拒否時でもエラーなし

    func test_recording_withoutMicPermission_recordsVideoOnly() {
        sut.micPermissionGranted = false
        sut.startRecording()

        XCTAssertTrue(sut.isRecording, "マイク拒否でもエラーにならず録画できる必要があります")
        XCTAssertFalse(sut.isAudioEnabled, "マイク拒否時は音声なしで録画する必要があります")
    }

    // MARK: - T-15.15: 動画モード切替でプリセット変更

    func test_switchToVideoMode_changesPreset() {
        sut.switchToVideoMode()

        XCTAssertEqual(
            sut.currentPreset,
            CameraConfig.videoPreset,
            "動画モードでプリセットが720pに変更される必要があります"
        )
    }

    // MARK: - T-15.16: 写真モード切替でプリセット復元

    func test_switchToPhotoMode_restoresPreset() {
        sut.switchToVideoMode()
        sut.switchToPhotoMode()

        XCTAssertEqual(
            sut.currentPreset,
            CameraConfig.sessionPreset,
            "写真モードでプリセットが.photoに復元される必要があります"
        )
    }

    // MARK: - T-15.17: 録画中のモード切替は無効

    func test_switchMode_duringRecording_isBlocked() {
        sut.startRecording()
        XCTAssertTrue(sut.isRecording)

        sut.switchToPhotoMode()

        XCTAssertEqual(
            sut.currentPreset,
            CameraConfig.videoPreset,
            "録画中はモード切替が無効化される必要があります"
        )
    }
}
