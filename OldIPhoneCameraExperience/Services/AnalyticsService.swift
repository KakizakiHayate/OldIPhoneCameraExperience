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

    // MARK: - Event Names

    private enum EventName {
        static let photoCaptured = "photo_captured"
        static let videoRecorded = "video_recorded"
        static let cameraModelSelected = "camera_model_selected"
        static let aspectRatioChanged = "aspect_ratio_changed"
        static let cameraPositionSwitched = "camera_position_switched"
        static let flashToggled = "flash_toggled"
        static let photoEditorOpened = "photo_editor_opened"
        static let photoSaved = "photo_saved"
        static let cameraError = "camera_error"
    }

    // MARK: - Parameter Keys

    private enum ParamKey {
        static let cameraModel = "camera_model"
        static let cameraPosition = "camera_position"
        static let flashEnabled = "flash_enabled"
        static let aspectRatio = "aspect_ratio"
        static let zoomFactor = "zoom_factor"
        static let durationSeconds = "duration_seconds"
        static let modelName = "model_name"
        static let newRatio = "new_ratio"
        static let newPosition = "new_position"
        static let flashState = "flash_state"
        static let captureMode = "capture_mode"
        static let brightness = "brightness"
        static let contrast = "contrast"
        static let saturation = "saturation"
        static let cropApplied = "crop_applied"
        static let errorType = "error_type"
        static let errorDescription = "error_description"
    }

    // MARK: - 撮影イベント

    func logPhotoCaptured(
        cameraModel: String,
        cameraPosition: String,
        flashEnabled: Bool,
        aspectRatio: String,
        zoomFactor: CGFloat
    ) {
        Analytics.logEvent(EventName.photoCaptured, parameters: [
            ParamKey.cameraModel: cameraModel,
            ParamKey.cameraPosition: cameraPosition,
            ParamKey.flashEnabled: flashEnabled,
            ParamKey.aspectRatio: aspectRatio,
            ParamKey.zoomFactor: zoomFactor
        ])
    }

    func logVideoRecorded(
        cameraModel: String,
        cameraPosition: String,
        flashEnabled: Bool,
        durationSeconds: TimeInterval
    ) {
        Analytics.logEvent(EventName.videoRecorded, parameters: [
            ParamKey.cameraModel: cameraModel,
            ParamKey.cameraPosition: cameraPosition,
            ParamKey.flashEnabled: flashEnabled,
            ParamKey.durationSeconds: durationSeconds
        ])
    }

    // MARK: - カメラ設定イベント

    func logCameraModelSelected(modelName: String) {
        Analytics.logEvent(EventName.cameraModelSelected, parameters: [
            ParamKey.modelName: modelName
        ])
    }

    func logAspectRatioChanged(newRatio: String) {
        Analytics.logEvent(EventName.aspectRatioChanged, parameters: [
            ParamKey.newRatio: newRatio
        ])
    }

    func logCameraPositionSwitched(newPosition: String) {
        Analytics.logEvent(EventName.cameraPositionSwitched, parameters: [
            ParamKey.newPosition: newPosition
        ])
    }

    func logFlashToggled(flashState: Bool, captureMode: String) {
        Analytics.logEvent(EventName.flashToggled, parameters: [
            ParamKey.flashState: flashState ? "on" : "off",
            ParamKey.captureMode: captureMode
        ])
    }

    // MARK: - 編集イベント

    func logPhotoEditorOpened() {
        Analytics.logEvent(EventName.photoEditorOpened, parameters: nil)
    }

    func logPhotoSaved(brightness: Float, contrast: Float, saturation: Float, cropApplied: Bool) {
        Analytics.logEvent(EventName.photoSaved, parameters: [
            ParamKey.brightness: brightness,
            ParamKey.contrast: contrast,
            ParamKey.saturation: saturation,
            ParamKey.cropApplied: cropApplied
        ])
    }

    // MARK: - エラーイベント

    func logCameraError(errorType: String, errorDescription: String) {
        Analytics.logEvent(EventName.cameraError, parameters: [
            ParamKey.errorType: errorType,
            ParamKey.errorDescription: errorDescription
        ])
    }
}
