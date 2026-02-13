//
//  FilterParameters.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreGraphics

/// フィルター処理で使用する全定数を管理する enum
enum FilterParameters {
    // MARK: - 暖色系色味（F2.1）

    /// 色温度シフト量（K相当）。正の値で暖色方向
    static let warmthShift: CGFloat = 1000

    /// 彩度（1.0が標準、低いほどくすみ感）
    static let saturation: CGFloat = 0.9

    /// ハイライトへのオレンジティント強度
    static let highlightTintAmount: CGFloat = 0.1

    // MARK: - 画角クロップ（F2.2）

    /// クロップ率（26mm→32mm換算）。1.0でクロップなし
    static let cropRatio: CGFloat = 0.81

    /// 出力画像の幅（px）。iPhone 4の5MP相当
    static let outputWidth: Int = 2592

    /// 出力画像の高さ（px）
    static let outputHeight: Int = 1936

    // MARK: - 手ブレシミュレーション（F2.3）

    /// X/Y方向のシフト量範囲（px）
    static let shakeShiftRange: ClosedRange<CGFloat> = 1.0 ... 5.0

    /// 回転角度範囲（度）
    static let shakeRotationRange: ClosedRange<CGFloat> = -0.5 ... 0.5

    /// モーションブラー半径範囲
    static let motionBlurRadiusRange: ClosedRange<CGFloat> = 1.0 ... 3.0
}
