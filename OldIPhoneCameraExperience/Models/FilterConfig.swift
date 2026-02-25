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

    // MARK: - 手ブレシミュレーション（F2.3）

    /// X/Y方向のシフト量範囲（px）
    let shakeShiftRange: ClosedRange<Double>

    /// 回転角度範囲（度）
    let shakeRotationRange: ClosedRange<Double>

    /// モーションブラー半径範囲
    let motionBlurRadiusRange: ClosedRange<Double>

    // MARK: - 出力解像度

    /// 基準幅（横持ち基準、px）
    let baseWidth: Int

    /// 基準高さ（横持ち基準、px）
    let baseHeight: Int

    /// 出力画像の幅（px）— アスペクト比と基準解像度から算出
    var outputWidth: Int {
        switch aspectRatio {
        case .square: baseHeight
        case .standard: baseWidth
        case .wide: baseWidth
        }
    }

    /// 出力画像の高さ（px）— アスペクト比と基準解像度から算出
    var outputHeight: Int {
        switch aspectRatio {
        case .square: baseHeight
        case .standard: baseHeight
        case .wide: baseWidth * 9 / 16
        }
    }

    init(
        warmth: Double,
        tint: Double,
        saturation: Double,
        highlightTintIntensity: Double,
        cropRatio: Double,
        aspectRatio: AspectRatio = .standard,
        shakeShiftRange: ClosedRange<Double> = 1.0 ... 5.0,
        shakeRotationRange: ClosedRange<Double> = -0.5 ... 0.5,
        motionBlurRadiusRange: ClosedRange<Double> = 1.0 ... 3.0,
        baseWidth: Int = 2592,
        baseHeight: Int = 1936
    ) {
        self.warmth = warmth
        self.tint = tint
        self.saturation = saturation
        self.highlightTintIntensity = highlightTintIntensity
        self.cropRatio = cropRatio
        self.aspectRatio = aspectRatio
        self.shakeShiftRange = shakeShiftRange
        self.shakeRotationRange = shakeRotationRange
        self.motionBlurRadiusRange = motionBlurRadiusRange
        self.baseWidth = baseWidth
        self.baseHeight = baseHeight
    }
}

// MARK: - Presets

extension FilterConfig {
    /// iPhone 4 のフィルター設定（MVP）
    /// 手ブレ・解像度パラメータはinitのデフォルト値（iPhone 4相当）を使用
    static let iPhone4 = FilterConfig(
        warmth: Double(FilterParameters.warmthShift),
        tint: 10,
        saturation: Double(FilterParameters.saturation),
        highlightTintIntensity: Double(FilterParameters.highlightTintAmount),
        cropRatio: Double(FilterParameters.cropRatio)
    )

    /// iPhone 6 のフィルター設定
    static let iPhone6 = FilterConfig(
        warmth: 500,
        tint: 5,
        saturation: 0.95,
        highlightTintIntensity: 0.05,
        cropRatio: 0.87,
        shakeShiftRange: 0.5 ... 2.5,
        shakeRotationRange: -0.25 ... 0.25,
        motionBlurRadiusRange: 0.5 ... 1.5,
        baseWidth: 3264,
        baseHeight: 2448
    )
}
