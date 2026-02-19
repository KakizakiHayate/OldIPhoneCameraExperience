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

    /// アスペクト比（デフォルト: 4:3）
    let aspectRatio: AspectRatio

    /// 出力画像の幅（px）— アスペクト比から自動計算
    var outputWidth: Int {
        aspectRatio.outputWidth
    }

    /// 出力画像の高さ（px）— アスペクト比から自動計算
    var outputHeight: Int {
        aspectRatio.outputHeight
    }

    init(
        warmth: Double,
        tint: Double,
        saturation: Double,
        highlightTintIntensity: Double,
        cropRatio: Double,
        aspectRatio: AspectRatio = .standard
    ) {
        self.warmth = warmth
        self.tint = tint
        self.saturation = saturation
        self.highlightTintIntensity = highlightTintIntensity
        self.cropRatio = cropRatio
        self.aspectRatio = aspectRatio
    }
}

// MARK: - Presets

extension FilterConfig {
    /// iPhone 4 のフィルター設定（MVP）
    static let iPhone4 = FilterConfig(
        warmth: Double(FilterParameters.warmthShift),
        tint: 10,
        saturation: Double(FilterParameters.saturation),
        highlightTintIntensity: Double(FilterParameters.highlightTintAmount),
        cropRatio: Double(FilterParameters.cropRatio)
    )
}
