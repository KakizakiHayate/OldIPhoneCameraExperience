//
//  CaptureResult.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import UIKit

/// 撮影結果を表すモデル
struct CaptureResult {
    /// フィルター適用済みの最終画像
    let image: UIImage

    /// 適用されたフィルター設定
    let filterConfig: FilterConfig

    /// 適用された手ブレパラメータ（nilの場合はブレなし）
    let shakeEffect: ShakeEffect?

    /// 撮影日時
    let capturedAt: Date

    /// 撮影時のカメラ（前面/背面）
    let cameraPosition: CameraPosition

    /// フラッシュ使用の有無
    let flashUsed: Bool

    /// 使用した再現機種
    let cameraModel: CameraModel
}
