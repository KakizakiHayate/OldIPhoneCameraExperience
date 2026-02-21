//
//  PhotoLibraryServiceVideoTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #43: 動画保存テスト
//

@testable import OldIPhoneCameraExperience
import XCTest

final class PhotoLibraryServiceVideoTests: XCTestCase {
    var sut: MockPhotoLibraryService!

    override func setUp() {
        super.setUp()
        sut = MockPhotoLibraryService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-16.7: 動画ファイルをカメラロールに保存

    func test_saveVideoToPhotoLibrary_completesSuccessfully() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".mov")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())

        try await sut.saveVideoToPhotoLibrary(tempURL)

        XCTAssertEqual(sut.savedVideoURLs.count, 1, "動画が1件保存されている必要があります")
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - T-16.8: 保存後の一時ファイル管理

    func test_saveVideoToPhotoLibrary_tracksURL() async throws {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".mov")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())

        try await sut.saveVideoToPhotoLibrary(tempURL)

        XCTAssertEqual(sut.savedVideoURLs.first, tempURL, "保存されたURLが正しい必要があります")
        try? FileManager.default.removeItem(at: tempURL)
    }

    // MARK: - T-16.10: 権限なしで保存するとエラー

    func test_saveVideoToPhotoLibrary_deniedPermission_throws() async {
        sut.shouldThrowError = true
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString + ".mov")

        do {
            try await sut.saveVideoToPhotoLibrary(tempURL)
            XCTFail("権限がない場合にエラーがスローされる必要があります")
        } catch {
            XCTAssertTrue(error is PhotoLibraryError)
        }
    }
}
