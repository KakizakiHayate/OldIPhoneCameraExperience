//
//  CameraModel.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation

/// 再現するiPhone機種の定義
struct CameraModel: Identifiable, Equatable {
    /// 一意の識別子（例: "iphone4"）
    let id: String

    /// 機種名（例: "iPhone 4"）
    let name: String

    /// 発売年
    let year: Int

    /// カメラ画素数（MP）
    let megapixels: Double

    /// 35mm換算焦点距離（mm）
    let focalLengthEquivalent: Double

    /// 対応iOSバージョン（例: "4〜7"）
    let supportedIOSRange: String

    /// フィルターパラメータ群
    let filterConfig: FilterConfig

    /// 無料で使用可能かどうか（MVPではiPhone 4のみtrue）
    let isFree: Bool
}

// MARK: - Presets

extension CameraModel {
    /// iPhone 4 のプリセット（MVP）
    static let iPhone4 = CameraModel(
        id: "iphone4",
        name: "iPhone 4",
        year: 2010,
        megapixels: 5.0,
        focalLengthEquivalent: 32.0,
        supportedIOSRange: "4〜7",
        filterConfig: .iPhone4,
        isFree: true
    )

    /// すべての機種一覧（Phase 2で拡張予定）
    static let allModels: [CameraModel] = [
        .iPhone4,
    ]
}
