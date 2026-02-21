//
//  CameraModel.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation

/// 再現するiPhone機種の定義
struct CameraModel: Equatable {
    /// 機種名（例: "iPhone 4"）
    let name: String

    /// 対応iOS世代（例: "iOS 4-6"）
    let era: String

    /// 発売年
    let year: Int

    /// カメラ画素数（MP）
    let megapixels: Double

    /// 焦点距離（mm換算）
    let focalLength: Double

    /// フィルターパラメータ群
    let filterConfig: FilterConfig

    /// 無料で使用可能かどうか（MVPではiPhone 4のみtrue）
    let isFree: Bool
}

// MARK: - Presets

extension CameraModel {
    /// iPhone 4 のプリセット（MVP）
    static let iPhone4 = CameraModel(
        name: "iPhone 4",
        era: "iOS 4-6",
        year: 2010,
        megapixels: 5.0,
        focalLength: 32.0,
        filterConfig: .iPhone4,
        isFree: true
    )

    /// すべての機種一覧（Phase 2で拡張予定）
    static let allModels: [CameraModel] = [
        .iPhone4
    ]
}
