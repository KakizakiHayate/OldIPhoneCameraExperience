//
//  UIConstants.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreGraphics
import Foundation

/// UI関連の定数を管理する enum
enum UIConstants {

    // MARK: - ツールバー

    /// トップツールバーの高さ
    static let topToolbarHeight: CGFloat = 44

    /// ボトムツールバーの高さ
    static let bottomToolbarHeight: CGFloat = 96

    // MARK: - シャッターボタン

    /// シャッターボタンの外径
    static let shutterButtonSize: CGFloat = 66

    /// シャッターボタンの内径
    static let shutterButtonInnerSize: CGFloat = 54

    // MARK: - サムネイル

    /// サムネイルのサイズ
    static let thumbnailSize: CGFloat = 44

    /// サムネイルの角丸半径
    static let thumbnailCornerRadius: CGFloat = 4

    // MARK: - アニメーション

    /// 虹彩絞りが閉じる時間（秒）
    static let irisCloseDuration: TimeInterval = 0.2

    /// 虹彩絞りが開く時間（秒）
    static let irisOpenDuration: TimeInterval = 0.3

    /// 白フェード演出の時間（秒）
    static let flashFadeDuration: TimeInterval = 0.15
}
