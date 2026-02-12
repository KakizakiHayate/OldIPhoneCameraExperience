//
//  ShakeEffectTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

import XCTest
import CoreMotion
@testable import OldIPhoneCameraExperience

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
        let effect = ShakeEffect.generate(from: nil)

        XCTAssertNotNil(effect, "generateメソッドはShakeEffectを生成する必要があります")
    }

    // MARK: - M-SE3: shiftX/shiftYが範囲内であること
    func test_generate_shiftValues_areWithinRange() {
        let effect = ShakeEffect.generate(from: nil)
        let range = FilterParameters.shakeShiftRange

        XCTAssertGreaterThanOrEqual(effect.shiftX, Double(range.lowerBound))
        XCTAssertLessThanOrEqual(effect.shiftX, Double(range.upperBound))
        XCTAssertGreaterThanOrEqual(effect.shiftY, Double(range.lowerBound))
        XCTAssertLessThanOrEqual(effect.shiftY, Double(range.upperBound))
    }

    // MARK: - M-SE4: rotationが範囲内であること
    func test_generate_rotation_isWithinRange() {
        let effect = ShakeEffect.generate(from: nil)
        let range = FilterParameters.shakeRotationRange

        XCTAssertGreaterThanOrEqual(effect.rotation, Double(range.lowerBound))
        XCTAssertLessThanOrEqual(effect.rotation, Double(range.upperBound))
    }

    // MARK: - M-SE5: motionBlurRadiusが範囲内であること
    func test_generate_motionBlurRadius_isWithinRange() {
        let effect = ShakeEffect.generate(from: nil)
        let range = FilterParameters.motionBlurRadiusRange

        XCTAssertGreaterThanOrEqual(effect.motionBlurRadius, Double(range.lowerBound))
        XCTAssertLessThanOrEqual(effect.motionBlurRadius, Double(range.upperBound))
    }
}
