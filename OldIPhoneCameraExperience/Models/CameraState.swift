//
//  CameraState.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation

/// カメラの現在の動作状態を表すモデル
struct CameraState {
    var isFlashOn: Bool
    var cameraPosition: CameraPosition
    var isCapturing: Bool
    var permissionStatus: PermissionStatus

    init(
        isFlashOn: Bool = false,
        cameraPosition: CameraPosition = .back,
        isCapturing: Bool = false,
        permissionStatus: PermissionStatus = .notDetermined
    ) {
        self.isFlashOn = isFlashOn
        self.cameraPosition = cameraPosition
        self.isCapturing = isCapturing
        self.permissionStatus = permissionStatus
    }
}

/// カメラの位置（前面/背面）
enum CameraPosition: CaseIterable {
    case front
    case back
}

/// 撮影モード（写真/動画）
enum CaptureMode: CaseIterable {
    case photo
    case video
}

/// カメラ権限の状態
enum PermissionStatus: CaseIterable {
    case notDetermined // 未決定（初回起動前）
    case authorized // 許可済み
    case denied // 拒否
}
