//
//  CameraScreenZoomTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #41: ズームUI — ピンチジェスチャー + インジケーター統合テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class CameraScreenZoomTests: XCTestCase {
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

    // MARK: - T-14.1: ピンチアウト（拡大）でzoomFactorが増加

    func test_pinchOut_increasesZoomFactor() {
        let baseZoom: CGFloat = 1.0
        let pinchScale: CGFloat = 2.0
        let newZoom = baseZoom * pinchScale

        viewModel.setZoom(factor: newZoom)

        XCTAssertEqual(viewModel.zoomFactor, 2.0, "ピンチアウトでzoomFactorが増加する必要があります")
    }

    // MARK: - T-14.2: ピンチイン（縮小）でzoomFactorが減少

    func test_pinchIn_decreasesZoomFactor() {
        viewModel.setZoom(factor: 3.0)
        let baseZoom: CGFloat = 3.0
        let pinchScale: CGFloat = 0.5
        let newZoom = baseZoom * pinchScale

        viewModel.setZoom(factor: newZoom)

        XCTAssertEqual(viewModel.zoomFactor, 1.5, "ピンチインでzoomFactorが減少する必要があります")
    }

    // MARK: - T-14.3: 最大5倍を超えるピンチアウトはクランプされる

    func test_pinchOut_beyondMax_clampsToMax() {
        let baseZoom: CGFloat = 4.0
        let pinchScale: CGFloat = 2.0
        let newZoom = baseZoom * pinchScale // 8.0

        viewModel.setZoom(factor: newZoom)

        XCTAssertEqual(viewModel.zoomFactor, CameraConfig.maxZoomFactor, "最大5倍を超えるズームは5.0にクランプされる必要があります")
    }

    // MARK: - T-14.4: 最小0.5倍を下回るピンチインはクランプされる

    func test_pinchIn_belowMin_clampsToMin() {
        viewModel.setZoom(factor: 2.0)
        let baseZoom: CGFloat = 2.0
        let pinchScale: CGFloat = 0.2
        let newZoom = baseZoom * pinchScale // 0.4

        viewModel.setZoom(factor: newZoom)

        XCTAssertEqual(viewModel.zoomFactor, CameraConfig.minZoomFactor, "最小0.5倍を下回るズームは0.5にクランプされる必要があります")
    }

    // MARK: - T-14.5: 2.0倍の状態から1.5倍のピンチアウトで3.0倍

    func test_pinchFromBase_multipliesCorrectly() {
        viewModel.setZoom(factor: 2.0)
        let baseZoom: CGFloat = 2.0
        let pinchScale: CGFloat = 1.5
        let newZoom = baseZoom * pinchScale

        viewModel.setZoom(factor: newZoom)

        XCTAssertEqual(viewModel.zoomFactor, 3.0, "2.0 × 1.5 = 3.0 になる必要があります")
    }

    // MARK: - T-14.11: フェード中に再度ピンチ操作でタイマーリセット確認

    func test_zoomIndicator_timerResetOnNewGesture() {
        // ZoomIndicatorのタイマーリセットはView層の@State管理
        // ViewModelのzoomFactorが連続更新されることを確認
        viewModel.setZoom(factor: 2.0)
        XCTAssertEqual(viewModel.zoomFactor, 2.0)

        viewModel.setZoom(factor: 3.0)
        XCTAssertEqual(viewModel.zoomFactor, 3.0, "連続的なズーム操作でzoomFactorが正しく更新される必要があります")
    }

    // MARK: - T-14.6: UIConstants にズームインジケーター定数が定義されている

    func test_zoomIndicator_constantsDefined() {
        XCTAssertEqual(UIConstants.zoomIndicatorFadeDelay, 2.0, "フェード遅延は2.0秒である必要があります")
        XCTAssertEqual(UIConstants.zoomIndicatorFadeDuration, 0.3, "フェード時間は0.3秒である必要があります")
    }
}
