//
//  CropOverlayView.swift
//  OldIPhoneCameraExperience
//
//  Issue #50: トリミングオーバーレイUI
//

import SwiftUI

/// 画像上に表示するクロップ枠オーバーレイ
struct CropOverlayView: View {
    @Binding var cropRect: CGRect
    let imageBounds: CGRect
    let cropMode: CropMode

    private let handleSize: CGFloat = 20
    private let handleLineWidth: CGFloat = 3
    private let overlayOpacity: Double = 0.5

    var body: some View {
        GeometryReader { geometry in
            let bounds = geometry.size
            ZStack {
                // セミダークオーバーレイ（枠外）
                darkOverlay(in: bounds)

                // クロップ枠
                Rectangle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(
                        x: cropRect.midX,
                        y: cropRect.midY
                    )

                // 四隅のハンドル
                cornerHandles
            }
            .gesture(moveGesture)
        }
    }

    // MARK: - Dark Overlay

    private func darkOverlay(in size: CGSize) -> some View {
        Path { path in
            path.addRect(CGRect(origin: .zero, size: size))
            path.addRect(cropRect)
        }
        .fill(Color.black.opacity(overlayOpacity), style: FillStyle(eoFill: true))
    }

    // MARK: - Corner Handles

    private var cornerHandles: some View {
        Group {
            cornerHandle(at: CGPoint(x: cropRect.minX, y: cropRect.minY), corner: .topLeft)
            cornerHandle(at: CGPoint(x: cropRect.maxX, y: cropRect.minY), corner: .topRight)
            cornerHandle(at: CGPoint(x: cropRect.minX, y: cropRect.maxY), corner: .bottomLeft)
            cornerHandle(at: CGPoint(x: cropRect.maxX, y: cropRect.maxY), corner: .bottomRight)
        }
    }

    private func cornerHandle(at point: CGPoint, corner: CropCorner) -> some View {
        CornerHandleShape(corner: corner, size: handleSize)
            .stroke(Color.white, lineWidth: handleLineWidth)
            .frame(width: handleSize, height: handleSize)
            .position(x: point.x, y: point.y)
            .gesture(resizeGesture(corner: corner))
    }

    // MARK: - Gestures

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { gesture in
                let delta = CGSize(
                    width: gesture.translation.width,
                    height: gesture.translation.height
                )
                cropRect = CropRectCalculator.moveRect(
                    currentRect: cropRect,
                    dragDelta: delta,
                    imageBounds: imageBounds
                )
            }
    }

    private func resizeGesture(corner: CropCorner) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let delta = CGSize(
                    width: gesture.translation.width,
                    height: gesture.translation.height
                )
                cropRect = CropRectCalculator.resizeFromCorner(
                    currentRect: cropRect,
                    corner: corner,
                    dragDelta: delta,
                    cropMode: cropMode,
                    imageBounds: imageBounds
                )
            }
    }
}

// MARK: - Corner Handle Shape

private struct CornerHandleShape: Shape {
    let corner: CropCorner
    let size: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = size * 0.7

        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: 0, y: length))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: length, y: 0))
        case .topRight:
            path.move(to: CGPoint(x: rect.maxX - length, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: length))
        case .bottomLeft:
            path.move(to: CGPoint(x: 0, y: rect.maxY - length))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: length, y: rect.maxY))
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        }

        return path
    }
}
