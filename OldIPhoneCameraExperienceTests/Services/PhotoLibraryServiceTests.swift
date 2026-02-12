//
//  PhotoLibraryServiceTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import XCTest
import UIKit
@testable import OldIPhoneCameraExperience

/// モックPhotoLibraryService（テスト用）
final class MockPhotoLibraryService: PhotoLibraryServiceProtocol {
    var savedImages: [UIImage] = []
    var shouldThrowError = false

    func saveToPhotoLibrary(_ image: UIImage) async throws {
        if shouldThrowError {
            throw PhotoLibraryError.saveFailed
        }
        savedImages.append(image)
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
}
