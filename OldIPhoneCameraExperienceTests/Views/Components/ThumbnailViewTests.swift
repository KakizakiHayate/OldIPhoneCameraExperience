//
//  ThumbnailViewTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import UIKit
import XCTest

final class ThumbnailViewTests: XCTestCase {
    // MARK: - V-BT1: image == nilでThumbnailViewが生成できること

    func test_thumbnailView_withNilImage_canBeCreated() {
        let view = ThumbnailView(image: nil)

        XCTAssertNil(view.image, "image == nilでThumbnailViewが生成できる必要があります")
    }

    // MARK: - V-BT2: image != nilでThumbnailViewが生成できること

    func test_thumbnailView_withImage_canBeCreated() {
        let testImage = UIImage()
        let view = ThumbnailView(image: testImage)

        XCTAssertNotNil(view.image, "image != nilでThumbnailViewが生成できる必要があります")
    }

    // MARK: - V-BT3: サムネイルサイズがUIConstants.thumbnailSizeであること

    func test_thumbnailSize_matchesUIConstants() {
        let expectedSize = UIConstants.thumbnailSize

        XCTAssertEqual(expectedSize, 44, "サムネイルサイズはUIConstants.thumbnailSize(44)である必要があります")
        XCTAssertGreaterThan(expectedSize, 0, "サムネイルサイズは正の値である必要があります")
    }
}
