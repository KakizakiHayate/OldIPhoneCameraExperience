//
//  CropRectCalculator.swift
//  OldIPhoneCameraExperience
//
//  Issue #49: クロップ矩形の計算ユーティリティ
//

import CoreGraphics

/// クロップ矩形の角
enum CropCorner {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

/// クロップ矩形のリサイズ・移動計算
enum CropRectCalculator {
    /// 角ドラッグによるリサイズ
    static func resizeFromCorner(
        currentRect: CGRect,
        corner: CropCorner,
        dragDelta: CGSize,
        cropMode: CropMode,
        imageBounds: CGRect
    ) -> CGRect {
        var newRect = applyCornerDrag(currentRect: currentRect, corner: corner, dragDelta: dragDelta)

        if case let .fixed(aspectRatio) = cropMode {
            newRect = enforceAspectRatio(newRect, ratio: aspectRatio, corner: corner, anchor: currentRect)
        }

        newRect = clampToBounds(newRect, bounds: imageBounds)
        newRect = enforceMinimumSize(newRect)

        return newRect
    }

    /// 矩形の移動（サイズ不変）
    static func moveRect(
        currentRect: CGRect,
        dragDelta: CGSize,
        imageBounds: CGRect
    ) -> CGRect {
        var newX = currentRect.origin.x + dragDelta.width
        var newY = currentRect.origin.y + dragDelta.height

        newX = max(imageBounds.minX, min(newX, imageBounds.maxX - currentRect.width))
        newY = max(imageBounds.minY, min(newY, imageBounds.maxY - currentRect.height))

        return CGRect(x: newX, y: newY, width: currentRect.width, height: currentRect.height)
    }

    // MARK: - Private

    private static func applyCornerDrag(
        currentRect: CGRect,
        corner: CropCorner,
        dragDelta: CGSize
    ) -> CGRect {
        switch corner {
        case .bottomRight:
            return CGRect(
                x: currentRect.origin.x,
                y: currentRect.origin.y,
                width: currentRect.width + dragDelta.width,
                height: currentRect.height + dragDelta.height
            )
        case .bottomLeft:
            return CGRect(
                x: currentRect.origin.x + dragDelta.width,
                y: currentRect.origin.y,
                width: currentRect.width - dragDelta.width,
                height: currentRect.height + dragDelta.height
            )
        case .topRight:
            return CGRect(
                x: currentRect.origin.x,
                y: currentRect.origin.y + dragDelta.height,
                width: currentRect.width + dragDelta.width,
                height: currentRect.height - dragDelta.height
            )
        case .topLeft:
            return CGRect(
                x: currentRect.origin.x + dragDelta.width,
                y: currentRect.origin.y + dragDelta.height,
                width: currentRect.width - dragDelta.width,
                height: currentRect.height - dragDelta.height
            )
        }
    }

    private static func enforceAspectRatio(
        _ rect: CGRect,
        ratio: AspectRatio,
        corner: CropCorner,
        anchor: CGRect
    ) -> CGRect {
        let targetRatio = ratio.widthRatio / ratio.heightRatio
        let newWidth = rect.width
        let adjustedHeight = newWidth / targetRatio

        switch corner {
        case .bottomRight, .bottomLeft:
            return CGRect(x: rect.origin.x, y: rect.origin.y, width: newWidth, height: adjustedHeight)
        case .topRight, .topLeft:
            let newY = anchor.maxY - adjustedHeight
            return CGRect(x: rect.origin.x, y: newY, width: newWidth, height: adjustedHeight)
        }
    }

    private static func clampToBounds(_ rect: CGRect, bounds: CGRect) -> CGRect {
        let x = max(bounds.minX, rect.origin.x)
        let y = max(bounds.minY, rect.origin.y)
        let maxWidth = bounds.maxX - x
        let maxHeight = bounds.maxY - y
        let clampedWidth = min(rect.width, maxWidth)
        let clampedHeight = min(rect.height, maxHeight)

        return CGRect(x: x, y: y, width: max(clampedWidth, 0), height: max(clampedHeight, 0))
    }

    private static func enforceMinimumSize(_ rect: CGRect) -> CGRect {
        let minSize = EditorConstants.minimumCropSize
        let width = max(rect.width, minSize)
        let height = max(rect.height, minSize)
        return CGRect(x: rect.origin.x, y: rect.origin.y, width: width, height: height)
    }
}
