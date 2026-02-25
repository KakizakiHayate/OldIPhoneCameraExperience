//
//  AspectRatio.swift
//  OldIPhoneCameraExperience
//
//  Issue #45: 写真アスペクト比モデル
//

import CoreGraphics

/// 写真撮影のアスペクト比（動画は16:9固定で切替不可）
enum AspectRatio: CaseIterable {
    /// 1:1（Instagram等のSNS投稿用）
    case square

    /// 4:3（iPhone 4のデフォルト）
    case standard

    /// 16:9（ワイド）
    case wide

    /// 横比率（例: 4:3 → 4）
    var widthRatio: CGFloat {
        switch self {
        case .square: 1
        case .standard: 4
        case .wide: 16
        }
    }

    /// 縦比率（例: 4:3 → 3）
    var heightRatio: CGFloat {
        switch self {
        case .square: 1
        case .standard: 3
        case .wide: 9
        }
    }

    /// 縦持ち時のアスペクト比（width/height）
    var portraitRatio: CGFloat {
        heightRatio / widthRatio
    }

    /// 表示用ラベル
    var displayLabel: String {
        switch self {
        case .square: "1:1"
        case .standard: "4:3"
        case .wide: "16:9"
        }
    }

    /// 次のアスペクト比（循環: standard → square → wide → standard）
    func next() -> AspectRatio {
        switch self {
        case .standard: .square
        case .square: .wide
        case .wide: .standard
        }
    }
}
