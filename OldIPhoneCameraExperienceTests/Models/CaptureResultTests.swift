//
//  CaptureResultTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import UIKit
import XCTest

final class CaptureResultTests: XCTestCase {
    // MARK: - M-CR1: 全プロパティを指定して生成できること

    func test_initialization_withAllProperties() {
        let image = UIImage()
        let filterConfig = FilterConfig.iPhone4
        let shakeEffect = ShakeEffect(
            shiftX: 2.0, shiftY: 3.0, rotation: 0.2,
            motionBlurRadius: 1.5, motionBlurAngle: 45.0
        )
        let capturedAt = Date()
        let cameraModel = CameraModel.iPhone4

        let result = CaptureResult(
            image: image,
            filterConfig: filterConfig,
            shakeEffect: shakeEffect,
            capturedAt: capturedAt,
            cameraPosition: .back,
            flashUsed: true,
            cameraModel: cameraModel
        )

        XCTAssertEqual(result.image, image)
        XCTAssertEqual(result.filterConfig.warmth, filterConfig.warmth)
        XCTAssertEqual(result.shakeEffect?.shiftX, shakeEffect.shiftX)
        XCTAssertEqual(result.capturedAt, capturedAt)
        XCTAssertEqual(result.cameraPosition, .back)
        XCTAssertTrue(result.flashUsed)
        XCTAssertEqual(result.cameraModel.name, cameraModel.name)
    }

    // MARK: - M-CR2: shakeEffectがnilの生成ができること

    func test_initialization_withNilShakeEffect() {
        let result = CaptureResult(
            image: UIImage(),
            filterConfig: FilterConfig.iPhone4,
            shakeEffect: nil,
            capturedAt: Date(),
            cameraPosition: .front,
            flashUsed: false,
            cameraModel: CameraModel.iPhone4
        )

        XCTAssertNil(result.shakeEffect, "shakeEffectはnilを許容する必要があります")
    }

    // MARK: - M-CR3: capturedAtが現在時刻に近い値であること

    func test_capturedAt_isCloseToCurrentTime() {
        let before = Date()
        let result = CaptureResult(
            image: UIImage(),
            filterConfig: FilterConfig.iPhone4,
            shakeEffect: nil,
            capturedAt: Date(),
            cameraPosition: .back,
            flashUsed: false,
            cameraModel: CameraModel.iPhone4
        )
        let after = Date()

        XCTAssertGreaterThanOrEqual(result.capturedAt, before)
        XCTAssertLessThanOrEqual(result.capturedAt, after)

        let timeDifference = abs(result.capturedAt.timeIntervalSince(Date()))
        XCTAssertLessThan(timeDifference, 1.0, "capturedAtは現在時刻から1秒以内である必要があります")
    }
}
