//
//  ShakeEffectTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import CoreMotion
@testable import OldIPhoneCameraExperience
import XCTest

final class ShakeEffectTests: XCTestCase {
    // MARK: - M-SE1: 任意の値でShakeEffectを生成できること

    func test_initialization() {
        let effect = ShakeEffect(
            shiftX: 2.5,
            shiftY: 3.0,
            rotation: 0.3,
            motionBlurRadius: 2.0,
            motionBlurAngle: 45.0
        )

        XCTAssertEqual(effect.shiftX, 2.5)
        XCTAssertEqual(effect.shiftY, 3.0)
        XCTAssertEqual(effect.rotation, 0.3)
        XCTAssertEqual(effect.motionBlurRadius, 2.0)
        XCTAssertEqual(effect.motionBlurAngle, 45.0)
    }

    // MARK: - M-SE2: generateメソッドでShakeEffectが生成されること

    func test_generate_returnsNonNilEffect() {
        let effect = ShakeEffect.generate(from: nil, config: .iPhone4)

        XCTAssertNotNil(effect, "generateメソッドはShakeEffectを生成する必要があります")
    }

    // MARK: - M-SE3: shiftX/shiftYが範囲内であること

    func test_generate_shiftValues_areWithinRange() {
        let config = FilterConfig.iPhone4
        let effect = ShakeEffect.generate(from: nil, config: config)

        XCTAssertGreaterThanOrEqual(effect.shiftX, config.shakeShiftRange.lowerBound)
        XCTAssertLessThanOrEqual(effect.shiftX, config.shakeShiftRange.upperBound)
        XCTAssertGreaterThanOrEqual(effect.shiftY, config.shakeShiftRange.lowerBound)
        XCTAssertLessThanOrEqual(effect.shiftY, config.shakeShiftRange.upperBound)
    }

    // MARK: - M-SE4: rotationが範囲内であること

    func test_generate_rotation_isWithinRange() {
        let config = FilterConfig.iPhone4
        let effect = ShakeEffect.generate(from: nil, config: config)

        XCTAssertGreaterThanOrEqual(effect.rotation, config.shakeRotationRange.lowerBound)
        XCTAssertLessThanOrEqual(effect.rotation, config.shakeRotationRange.upperBound)
    }

    // MARK: - M-SE5: motionBlurRadiusが範囲内であること

    func test_generate_motionBlurRadius_isWithinRange() {
        let config = FilterConfig.iPhone4
        let effect = ShakeEffect.generate(from: nil, config: config)

        XCTAssertGreaterThanOrEqual(effect.motionBlurRadius, config.motionBlurRadiusRange.lowerBound)
        XCTAssertLessThanOrEqual(effect.motionBlurRadius, config.motionBlurRadiusRange.upperBound)
    }
}
