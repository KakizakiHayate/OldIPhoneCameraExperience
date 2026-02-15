//
//  CameraPreviewView.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import SwiftUI

/// カメラプレビュー（AVCaptureVideoPreviewLayer を SwiftUI で表示）
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var cropRatio: CGFloat = 1.0

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        view.clipsToBounds = true

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds

        view.layer.addSublayer(previewLayer)

        // レイヤーをコンテキストに保存（updateUIViewで使用）
        context.coordinator.previewLayer = previewLayer

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // ビューのサイズが変わった時にレイヤーのフレームを更新
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
                // cropRatioに合わせてズームし、撮影写真と同じ範囲を表示する
                if cropRatio < 1.0 {
                    let scale = 1.0 / cropRatio
                    previewLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
