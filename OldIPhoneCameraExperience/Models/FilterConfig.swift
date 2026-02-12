//
//  FilterConfig.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation

/// フィルターのパラメータセットを表すモデル
struct FilterConfig {
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
        warmth: 1000,
        tint: 10,
        saturation: 0.9,
        highlightTintIntensity: 0.1,
        cropRatio: 0.81,
        outputWidth: 2592,
        outputHeight: 1936
    )
}
