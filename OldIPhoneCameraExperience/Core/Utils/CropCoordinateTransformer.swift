//
//  CropCoordinateTransformer.swift
//  OldIPhoneCameraExperience
//
//  Issue #49: ビュー座標⇔画像座標変換
//

import CoreGraphics

/// ビュー座標系（Y軸下向き）と画像座標系（CIImage、Y軸上向き）の相互変換
struct CropCoordinateTransformer {
    let imageSize: CGSize
    let viewSize: CGSize

    private var scaleX: CGFloat {
        guard viewSize.width > 0 else { return 1.0 }
        return imageSize.width / viewSize.width
    }

    private var scaleY: CGFloat {
        guard viewSize.height > 0 else { return 1.0 }
        return imageSize.height / viewSize.height
    }

    /// ビュー座標の矩形を画像座標に変換する（Y軸反転）
    func toImageRect(_ viewRect: CGRect) -> CGRect {
        let imageX = viewRect.origin.x * scaleX
        let imageW = viewRect.width * scaleX
        let imageH = viewRect.height * scaleY
        let imageY = (viewSize.height - viewRect.origin.y - viewRect.height) * scaleY

        return CGRect(x: imageX, y: imageY, width: imageW, height: imageH)
    }

    /// 画像座標の矩形をビュー座標に変換する（Y軸反転）
    func toViewRect(_ imageRect: CGRect) -> CGRect {
        let viewX = imageRect.origin.x / scaleX
        let viewW = imageRect.width / scaleX
        let viewH = imageRect.height / scaleY
        let viewY = viewSize.height - (imageRect.origin.y / scaleY) - viewH

        return CGRect(x: viewX, y: viewY, width: viewW, height: viewH)
    }
}
