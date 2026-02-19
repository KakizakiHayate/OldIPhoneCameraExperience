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

    /// プレビューのアスペクト比（3:4 縦長 — 縦持ち専用アプリのため）
    static let previewAspectRatio: CGFloat = 3.0 / 4.0

    /// ターゲットFPS
    static let targetFPS: Int = 30

    // MARK: - ズーム設定

    /// 最小ズーム倍率
    static let minZoomFactor: CGFloat = 1.0

    /// 最大ズーム倍率（iPhone 4相当）
    static let maxZoomFactor: CGFloat = 5.0

    /// ズームアニメーション速度
    static let zoomAnimationRate: Float = 5.0

    // MARK: - アスペクト比

    /// デフォルトのアスペクト比（写真モード）
    static let defaultAspectRatio: AspectRatio = .standard

    // MARK: - 動画設定

    /// 動画撮影用のセッションプリセット（720p = iPhone 4相当）
    static let videoPreset: AVCaptureSession.Preset = .hd1280x720

    /// 動画のアスペクト比（16:9固定）
    static let videoAspectRatio: CGFloat = 16.0 / 9.0
}
