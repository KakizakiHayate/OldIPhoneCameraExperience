//
//  AspectRatioButtonTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #46: アスペクト比UI テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

@MainActor
final class AspectRatioButtonTests: XCTestCase {
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

    // MARK: - T-19.1: アプリ起動時のボタン表示が "4:3"

    func test_defaultAspectRatio_displaysStandard() {
        XCTAssertEqual(viewModel.aspectRatio.displayLabel, "4:3",
                       "起動時は4:3が表示される必要があります")
    }

    // MARK: - T-19.2: ボタンを1回タップで "1:1" に切替

    func test_tapOnce_switchesToSquare() {
        viewModel.setAspectRatio(viewModel.aspectRatio.next())

        XCTAssertEqual(viewModel.aspectRatio.displayLabel, "1:1",
                       "1回タップ後は1:1が表示される必要があります")
    }

    // MARK: - T-19.3: ボタンを2回タップで "16:9" に切替

    func test_tapTwice_switchesToWide() {
        viewModel.setAspectRatio(viewModel.aspectRatio.next())
        viewModel.setAspectRatio(viewModel.aspectRatio.next())

        XCTAssertEqual(viewModel.aspectRatio.displayLabel, "16:9",
                       "2回タップ後は16:9が表示される必要があります")
    }

    // MARK: - T-19.4: ボタンを3回タップで "4:3" に戻る

    func test_tapThreeTimes_loopsBackToStandard() {
        viewModel.setAspectRatio(viewModel.aspectRatio.next())
        viewModel.setAspectRatio(viewModel.aspectRatio.next())
        viewModel.setAspectRatio(viewModel.aspectRatio.next())

        XCTAssertEqual(viewModel.aspectRatio.displayLabel, "4:3",
                       "3回タップ後は4:3に戻る必要があります")
    }

    // MARK: - T-19.5: 動画モード時はアスペクト比変更不可

    func test_videoMode_aspectRatioChangeBlocked() {
        viewModel.switchToVideoMode()

        viewModel.setAspectRatio(.square)

        XCTAssertEqual(viewModel.aspectRatio, .standard,
                       "動画モードではアスペクト比変更が無効化される必要があります")
    }

    // MARK: - T-19.6: 動画モードから写真モードに戻るとアスペクト比が復元

    func test_switchBackToPhotoMode_restoresAspectRatio() {
        viewModel.setAspectRatio(.wide)
        viewModel.switchToVideoMode()

        viewModel.switchToPhotoMode()

        XCTAssertEqual(viewModel.aspectRatio, .wide,
                       "写真モードに戻った時、以前のアスペクト比が表示される必要があります")
    }

    // MARK: - T-19.7: 1:1選択時のプレビューアスペクト比

    func test_squareMode_previewRatio_isOne() {
        viewModel.setAspectRatio(.square)

        XCTAssertEqual(viewModel.aspectRatio.portraitRatio, 1.0, accuracy: 0.01,
                       "1:1選択時のプレビューは正方形である必要があります")
    }

    // MARK: - T-19.8: 4:3選択時のプレビューアスペクト比

    func test_standardMode_previewRatio_isThreeQuarters() {
        XCTAssertEqual(viewModel.aspectRatio.portraitRatio, 0.75, accuracy: 0.01,
                       "4:3選択時のプレビューは3:4である必要があります")
    }

    // MARK: - T-19.9: 16:9選択時のプレビューアスペクト比

    func test_wideMode_previewRatio_is9Over16() {
        viewModel.setAspectRatio(.wide)

        XCTAssertEqual(viewModel.aspectRatio.portraitRatio, 0.5625, accuracy: 0.01,
                       "16:9選択時のプレビューは9:16である必要があります")
    }

    // MARK: - T-19.13: テキスト表示のToolbarButton

    func test_toolbarButton_textVariant_canBeCreated() {
        let button = ToolbarButton(text: "4:3", action: {})

        if case let .text(text) = button.content {
            XCTAssertEqual(text, "4:3",
                           "テキスト表示のToolbarButtonが生成できる必要があります")
        } else {
            XCTFail("ToolbarButton(text:)のcontentは.textである必要があります")
        }
    }
}
