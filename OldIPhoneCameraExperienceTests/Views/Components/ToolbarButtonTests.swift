//
//  ToolbarButtonTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Created by Manus on 2026-02-13.
//

@testable import OldIPhoneCameraExperience
import XCTest

final class ToolbarButtonTests: XCTestCase {
    // MARK: - V-TB1: 非アクティブ状態で生成できること

    func test_toolbarButton_nonActiveState_canBeCreated() {
        let button = ToolbarButton(icon: "bolt.slash.fill", isActive: false, action: {})

        XCTAssertEqual(button.icon, "bolt.slash.fill", "iconが正しく設定される必要があります")
        XCTAssertFalse(button.isActive, "isActiveがfalseである必要があります")
    }

    // MARK: - V-TB2: アクティブ状態で生成できること

    func test_toolbarButton_activeState_canBeCreated() {
        let button = ToolbarButton(icon: "bolt.fill", isActive: true, action: {})

        XCTAssertEqual(button.icon, "bolt.fill", "iconが正しく設定される必要があります")
        XCTAssertTrue(button.isActive, "isActiveがtrueである必要があります")
    }

    // MARK: - V-TB3: actionクロージャが設定されていること

    func test_toolbarButton_actionClosureIsSet() {
        var actionCalled = false
        let button = ToolbarButton(icon: "bolt.fill", action: {
            actionCalled = true
        })

        button.action()

        XCTAssertTrue(actionCalled, "actionクロージャが呼ばれる必要があります")
    }

    // MARK: - V-TB4: iconプロパティが正しく設定されること

    func test_toolbarButton_iconProperty_isCorrectlySet() {
        let flashIcon = "bolt.fill"
        let cameraIcon = "arrow.triangle.2.circlepath.camera"

        let flashButton = ToolbarButton(icon: flashIcon, action: {})
        let cameraButton = ToolbarButton(icon: cameraIcon, action: {})

        XCTAssertEqual(flashButton.icon, flashIcon, "フラッシュアイコンが正しく設定される必要があります")
        XCTAssertEqual(cameraButton.icon, cameraIcon, "カメラ切替アイコンが正しく設定される必要があります")
    }
}
