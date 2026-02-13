//
//  FilterConfig.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreGraphics
import Foundation

/// フィルターのパラメータセットを表すモデル
struct FilterConfig: Equatable {
    // MARK: - 暖色系の色味（F2.1）

    /// 色温度シフト量（K相当）
    let warmth: Double

    /// ティント（緑-マゼンタ方向）
    let tint: Double

    /// 彩度（1.0が標準）
    let saturation: Double

    /// ハイライトへのオレンジティント強度
    let highlightTintIntensity: Double

    // MARK: - 画角クロップ（F2.2）

    /// クロップ率（1.0でクロップなし）
    let cropRatio: Double

    /// 出力画像の幅（px）
    let outputWidth: Int

    /// 出力画像の高さ（px）
    let outputHeight: Int
}

// MARK: - Presets

extension FilterConfig {
    /// iPhone 4 のフィルター設定（MVP）
    static let iPhone4 = FilterConfig(
        warmth: Double(FilterParameters.warmthShift),
        tint: 10,
        saturation: Double(FilterParameters.saturation),
        highlightTintIntensity: Double(FilterParameters.highlightTintAmount),
        cropRatio: Double(FilterParameters.cropRatio),
        outputWidth: FilterParameters.outputWidth,
        outputHeight: FilterParameters.outputHeight
    )
}
