//
//  CameraConfig.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import CoreGraphics

/// カメラ設定に関する定数を管理する enum
enum CameraConfig {

    /// デフォルトのカメラ位置（背面カメラ）
    static let defaultPosition: AVCaptureDevice.Position = .back

    /// キャプチャセッションのプリセット
    static let sessionPreset: AVCaptureSession.Preset = .photo

    /// プレビューのアスペクト比（4:3）
    static let previewAspectRatio: CGFloat = 4.0 / 3.0

    /// ターゲットFPS
    static let targetFPS: Int = 30
}
