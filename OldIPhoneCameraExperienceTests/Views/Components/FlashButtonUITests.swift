//
//  FlashButtonUITests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #47: フラッシュUI改善 + カメラ切替ボタン テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class FlashButtonUITests: XCTestCase {
    var viewModel: CameraViewModel!
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

        viewModel = CameraViewModel(
            cameraService: mockCameraService,
            filterService: mockFilterService,
            photoLibraryService: mockPhotoLibraryService,
            motionService: mockMotionService
        )
    }

    override func tearDown() {
        viewModel = nil
        mockCameraService = nil
        mockFilterService = nil
        mockPhotoLibraryService = nil
        mockMotionService = nil
        super.tearDown()
    }

    // MARK: - T-20.1: フラッシュOFF時のアイコン

    func test_flashOff_iconIsBoltSlash() {
        XCTAssertFalse(viewModel.state.isFlashOn)
        XCTAssertEqual(viewModel.flashIconName, "bolt.slash.fill",
                       "フラッシュOFF時はbolt.slash.fillアイコンである必要があります")
    }

    // MARK: - T-20.2: フラッシュON時のアイコン

    func test_flashOn_iconIsBoltFill() {
        viewModel.toggleFlash()

        XCTAssertTrue(viewModel.state.isFlashOn)
        XCTAssertEqual(viewModel.flashIconName, "bolt.fill",
                       "フラッシュON時はbolt.fillアイコンである必要があります")
    }

    // MARK: - T-20.4: 前面カメラ時のフラッシュ非表示

    func test_frontCamera_flashIsHidden() async throws {
        try await viewModel.startCamera()
        try await viewModel.switchCamera()

        XCTAssertEqual(viewModel.state.cameraPosition, .front)
        XCTAssertTrue(viewModel.shouldHideFlashButton,
                      "前面カメラ時はフラッシュボタンが非表示である必要があります")
    }

    // MARK: - T-20.5: 前面→背面カメラ切替後のフラッシュ再表示

    func test_switchBackToRear_flashIsVisible() async throws {
        try await viewModel.startCamera()
        try await viewModel.switchCamera()
        try await viewModel.switchCamera()

        XCTAssertEqual(viewModel.state.cameraPosition, .back)
        XCTAssertFalse(viewModel.shouldHideFlashButton,
                       "背面カメラ時はフラッシュボタンが表示される必要があります")
    }

    // MARK: - T-20.8: カメラ切替ボタンタップで切替

    func test_switchCamera_togglesPosition() async throws {
        try await viewModel.startCamera()

        try await viewModel.switchCamera()

        XCTAssertEqual(viewModel.state.cameraPosition, .front,
                       "カメラ切替後は前面カメラになる必要があります")
    }

    // MARK: - T-20.10: 動画モード時のフラッシュアイコン

    func test_videoMode_flashIcon_isTorch() {
        viewModel.switchToVideoMode()

        XCTAssertEqual(viewModel.flashIconName, "flashlight.off.fill",
                       "動画モードOFF時はflashlight.off.fillアイコンである必要があります")
    }

    // MARK: - T-20.11: 動画モードでトーチON

    func test_videoMode_torchOn_iconAndState() {
        viewModel.switchToVideoMode()
        viewModel.toggleFlash()

        XCTAssertTrue(viewModel.state.isFlashOn)
        XCTAssertEqual(viewModel.flashIconName, "flashlight.on.fill",
                       "動画モードON時はflashlight.on.fillアイコンである必要があります")
    }

    // MARK: - T-20.12: 動画トーチON → 写真モード切替後

    func test_torchOn_switchToPhoto_flashStaysOn() {
        viewModel.switchToVideoMode()
        viewModel.toggleFlash()

        viewModel.switchToPhotoMode()

        XCTAssertTrue(viewModel.state.isFlashOn,
                      "トーチONから写真モードに切替後もフラッシュONである必要があります")
        XCTAssertEqual(viewModel.flashIconName, "bolt.fill",
                       "写真モードではbolt.fillアイコンである必要があります")
    }
}
