//
//  IrisAnimationViewTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import SwiftUI
import XCTest

final class IrisAnimationViewTests: XCTestCase {
    // MARK: - V-IS1: isAnimating == falseで初期状態が正しいこと

    func test_irisAnimationView_initialState_isNotAnimating() {
        var isAnimating = false
        let binding = Binding(get: { isAnimating }, set: { isAnimating = $0 })
        let view = IrisAnimationView(isAnimating: binding)

        XCTAssertFalse(view.isAnimating, "初期状態ではisAnimatingがfalseである必要があります")
    }

    // MARK: - V-IS2: isAnimating変更時のアニメーション動作確認

    func test_irisAnimationView_animatingState_canBeTriggered() {
        var isAnimating = true
        let binding = Binding(get: { isAnimating }, set: { isAnimating = $0 })
        let view = IrisAnimationView(isAnimating: binding)

        XCTAssertTrue(view.isAnimating, "isAnimating == trueでアニメーション状態になる必要があります")
    }
}
