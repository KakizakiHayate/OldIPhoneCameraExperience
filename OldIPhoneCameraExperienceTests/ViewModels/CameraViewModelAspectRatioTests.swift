//
//  CameraViewModelAspectRatioTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #45: アスペクト比 ViewModel テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class CameraViewModelAspectRatioTests: XCTestCase {
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

    // MARK: - T-18.14: 初期化時のアスペクト比が.standard

    func test_defaultAspectRatio_isStandard() {
        XCTAssertEqual(sut.aspectRatio, .standard,
                       "初期化時のアスペクト比は.standard（4:3）である必要があります")
    }

    // MARK: - T-18.15: setAspectRatio(.square) で1:1に変更

    func test_setAspectRatio_square_changesAspectRatio() {
        sut.setAspectRatio(.square)

        XCTAssertEqual(sut.aspectRatio, .square,
                       "setAspectRatio(.square)後は1:1になる必要があります")
    }

    // MARK: - T-18.16: 動画モード時にsetAspectRatio(.square)→変更されない

    func test_setAspectRatio_inVideoMode_isBlocked() {
        sut.switchToVideoMode()

        sut.setAspectRatio(.square)

        XCTAssertEqual(sut.aspectRatio, .standard,
                       "動画モードではアスペクト比の変更が無効化される必要があります")
    }

    // MARK: - T-18.17: 動画モードから写真モードに戻ると以前のアスペクト比が維持

    func test_switchBackToPhotoMode_maintainsAspectRatio() {
        sut.setAspectRatio(.wide)
        XCTAssertEqual(sut.aspectRatio, .wide)

        sut.switchToVideoMode()
        sut.switchToPhotoMode()

        XCTAssertEqual(sut.aspectRatio, .wide,
                       "写真モードに戻った時、以前のアスペクト比が維持される必要があります")
    }
}
