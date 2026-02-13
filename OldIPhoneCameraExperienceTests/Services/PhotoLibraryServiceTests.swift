//
//  PhotoLibraryServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import UIKit
import XCTest

/// モックPhotoLibraryService（テスト用）
final class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    var savedImages: [UIImage] = []
    var shouldThrowError = false
    var permissionStatusToReturn: PermissionStatus = .authorized
    var latestPhotoToReturn: UIImage?

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        if shouldThrowError {
            throw PhotoLibraryError.saveFailed
        }
        savedImages.append(image)
    }

    func checkPermission() -> PermissionStatus {
        permissionStatusToReturn
    }

    func requestPermission() async -> PermissionStatus {
        permissionStatusToReturn
    }

    func fetchLatestPhoto() async -> UIImage? {
        latestPhotoToReturn
    }
}

final class PhotoLibraryServiceTests: XCTestCase {
    var sut: MockPhotoLibraryService!

    override func setUp() {
        super.setUp()
        sut = MockPhotoLibraryService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - S-P1: saveToPhotoLibraryが正常に完了する

    func test_saveToPhotoLibrary_completesSuccessfully() async throws {
        let testImage = UIImage()

        try await sut.saveToPhotoLibrary(testImage)

        XCTAssertEqual(sut.savedImages.count, 1, "画像が1枚保存されている必要があります")
    }

    // MARK: - S-P2: 複数回保存できる

    func test_saveToPhotoLibrary_canSaveMultipleTimes() async throws {
        let image1 = UIImage()
        let image2 = UIImage()

        try await sut.saveToPhotoLibrary(image1)
        try await sut.saveToPhotoLibrary(image2)

        XCTAssertEqual(sut.savedImages.count, 2, "画像が2枚保存されている必要があります")
    }

    // MARK: - S-P3: エラー時にthrowする

    func test_saveToPhotoLibrary_throwsErrorOnFailure() async {
        sut.shouldThrowError = true
        let testImage = UIImage()

        do {
            try await sut.saveToPhotoLibrary(testImage)
            XCTFail("エラーがthrowされる必要があります")
        } catch {
            XCTAssertTrue(error is PhotoLibraryError, "PhotoLibraryErrorがthrowされる必要があります")
        }
    }

    // MARK: - S-PL2: checkPermissionが.authorizedを返す

    func test_checkPermission_returnsAuthorized() {
        sut.permissionStatusToReturn = .authorized

        let status = sut.checkPermission()

        XCTAssertEqual(status, .authorized, "権限許可済みの場合、.authorizedを返す必要があります")
    }

    // MARK: - S-PL3: checkPermissionが.deniedを返す

    func test_checkPermission_returnsDenied() {
        sut.permissionStatusToReturn = .denied

        let status = sut.checkPermission()

        XCTAssertEqual(status, .denied, "権限拒否の場合、.deniedを返す必要があります")
    }

    // MARK: - S-PL4: requestPermissionが権限リクエストを実行

    func test_requestPermission_executesPermissionRequest() async {
        sut.permissionStatusToReturn = .authorized

        let status = await sut.requestPermission()

        XCTAssertEqual(status, .authorized, "requestPermissionが権限ステータスを返す必要があります")
    }

    // MARK: - S-PL5: fetchLatestPhotoがUIImageを返す

    func test_fetchLatestPhoto_returnsImage() async {
        let expectedImage = UIImage()
        sut.latestPhotoToReturn = expectedImage

        let result = await sut.fetchLatestPhoto()

        XCTAssertNotNil(result, "fetchLatestPhotoがUIImageを返す必要があります")
    }
}
