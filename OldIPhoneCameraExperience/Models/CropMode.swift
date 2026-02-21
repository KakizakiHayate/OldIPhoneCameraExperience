//
//  CropMode.swift
//  OldIPhoneCameraExperience
//
//  Issue #49: トリミングモード
//

import Foundation

/// トリミングモード
enum CropMode: Equatable {
    /// 自由なサイズでクロップ
    case free

    /// アスペクト比固定でクロップ
    case fixed(AspectRatio)
}
