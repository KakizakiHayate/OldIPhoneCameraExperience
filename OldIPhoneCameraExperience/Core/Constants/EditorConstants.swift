//
//  EditorConstants.swift
//  OldIPhoneCameraExperience
//
//  Issue #48: 写真編集パラメータ定数
//

import Foundation

/// 写真編集の各パラメータ範囲を管理する enum
enum EditorConstants {
    // MARK: - 明るさ

    /// 明るさの範囲（CIColorControls inputBrightness）
    static let brightnessRange: ClosedRange<Float> = -0.5 ... 0.5

    /// 明るさのデフォルト値
    static let defaultBrightness: Float = 0.0

    // MARK: - コントラスト

    /// コントラストの範囲（CIColorControls inputContrast）
    static let contrastRange: ClosedRange<Float> = 0.5 ... 2.0

    /// コントラストのデフォルト値
    static let defaultContrast: Float = 1.0

    // MARK: - 彩度

    /// 彩度の範囲（CIColorControls inputSaturation）
    static let saturationRange: ClosedRange<Float> = 0.0 ... 2.0

    /// 彩度のデフォルト値
    static let defaultSaturation: Float = 1.0
}
