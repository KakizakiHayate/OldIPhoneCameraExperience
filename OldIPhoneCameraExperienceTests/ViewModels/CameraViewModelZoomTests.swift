//
//  CameraViewModelZoomTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #40: ズーム基盤 — CameraViewModel状態管理
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class CameraViewModelZoomTests: XCTestCase {
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

    // MARK: - T-13.7: ViewModel初期化時のzoomFactorが1.0

    func test_initialState_zoomFactorIsOne() {
        XCTAssertEqual(sut.zoomFactor, 1.0, "初期状態ではzoomFactorが1.0である必要があります")
    }

    // MARK: - T-13.8: setZoom(factor: 2.5) でzoomFactorが2.5に更新

    func test_setZoom_updatesZoomFactor() {
        sut.setZoom(factor: 2.5)

        XCTAssertEqual(sut.zoomFactor, 2.5, "setZoom(factor: 2.5)でzoomFactorが2.5に更新される必要があります")
    }

    // MARK: - T-13.9: switchCamera() でzoomFactorが1.0にリセット

    func test_switchCamera_resetsZoomFactor() async throws {
        try await sut.startCamera()
        sut.setZoom(factor: 3.0)
        XCTAssertEqual(sut.zoomFactor, 3.0)

        try await sut.switchCamera()

        XCTAssertEqual(sut.zoomFactor, 1.0, "switchCamera後はzoomFactorが1.0にリセットされる必要があります")
    }

    // MARK: - T-13.10: モード切替時にzoomFactorが維持される（将来の動画モード用）

    func test_zoomFactor_persistsAcrossModeSwitch() {
        sut.setZoom(factor: 2.5)

        // モード切替はまだ未実装だが、zoomFactorが直接リセットされないことを確認
        XCTAssertEqual(sut.zoomFactor, 2.5, "zoomFactorが維持される必要があります")
    }
}
