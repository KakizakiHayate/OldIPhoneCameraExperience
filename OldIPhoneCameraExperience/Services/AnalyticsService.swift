//
//  AnalyticsService.swift
//  OldIPhoneCameraExperience
//
//  Issue #71: Firebase Analytics カスタムイベント送信
//

import FirebaseAnalytics
import Foundation

/// Analytics イベント送信を管理するサービス
final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    // MARK: - 撮影イベント

    func logPhotoCaptured(
        cameraModel: String,
        cameraPosition: String,
        flashEnabled: Bool,
        aspectRatio: String,
        zoomFactor: CGFloat
    ) {
        Analytics.logEvent("photo_captured", parameters: [
            "camera_model": cameraModel,
            "camera_position": cameraPosition,
            "flash_enabled": flashEnabled,
            "aspect_ratio": aspectRatio,
            "zoom_factor": zoomFactor
        ])
    }

    func logVideoRecorded(
        cameraModel: String,
        cameraPosition: String,
        flashEnabled: Bool,
        durationSeconds: TimeInterval
    ) {
        Analytics.logEvent("video_recorded", parameters: [
            "camera_model": cameraModel,
            "camera_position": cameraPosition,
            "flash_enabled": flashEnabled,
            "duration_seconds": durationSeconds
        ])
    }

    // MARK: - カメラ設定イベント

    func logCameraModelSelected(modelName: String) {
        Analytics.logEvent("camera_model_selected", parameters: [
            "model_name": modelName
        ])
    }

    func logAspectRatioChanged(newRatio: String) {
        Analytics.logEvent("aspect_ratio_changed", parameters: [
            "new_ratio": newRatio
        ])
    }

    func logCameraPositionSwitched(newPosition: String) {
        Analytics.logEvent("camera_position_switched", parameters: [
            "new_position": newPosition
        ])
    }

    func logFlashToggled(flashState: Bool, captureMode: String) {
        Analytics.logEvent("flash_toggled", parameters: [
            "flash_state": flashState ? "on" : "off",
            "capture_mode": captureMode
        ])
    }

    // MARK: - 編集イベント

    func logPhotoEditorOpened() {
        Analytics.logEvent("photo_editor_opened", parameters: nil)
    }

    func logPhotoSaved(brightness: Float, contrast: Float, saturation: Float, cropApplied: Bool) {
        Analytics.logEvent("photo_saved", parameters: [
            "brightness": brightness,
            "contrast": contrast,
            "saturation": saturation,
            "crop_applied": cropApplied
        ])
    }

    // MARK: - エラーイベント

    func logCameraError(errorType: String, errorDescription: String) {
        Analytics.logEvent("camera_error", parameters: [
            "error_type": errorType,
            "error_description": errorDescription
        ])
    }
}
