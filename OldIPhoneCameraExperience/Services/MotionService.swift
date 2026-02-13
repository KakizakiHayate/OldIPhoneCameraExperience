//
//  MotionService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreMotion
import Foundation
import os.log

/// ジャイロスコープデータの取得を提供するプロトコル
protocol MotionServiceProtocol {
    /// モニタリング中かどうか
    var isMonitoring: Bool { get }

    /// モーションデータのモニタリングを開始する
    func startMonitoring()

    /// モーションデータのモニタリングを停止する
    func stopMonitoring()

    /// 現在のモーションデータを取得する
    func getCurrentMotion() -> CMDeviceMotion?
}

/// ジャイロスコープデータの取得の実装
final class MotionService: MotionServiceProtocol {
    private static let logger = Logger(subsystem: "com.oldiPhonecamera", category: "MotionService")

    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()

    var isMonitoring: Bool {
        motionManager.isDeviceMotionActive
    }

    init() {
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.name = "com.oldiPhonecamera.motionQueue"
    }

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else {
            Self.logger.warning("Device motion is not available")
            return
        }

        guard !motionManager.isDeviceMotionActive else {
            Self.logger.info("Device motion is already active")
            return
        }

        // モーションデータの更新間隔を設定（60Hz）
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        // モーションデータの取得を開始
        motionManager.startDeviceMotionUpdates(to: operationQueue) { [weak self] _, error in
            if let error = error {
                Self.logger.error("Motion update error: \(error.localizedDescription)")
                return
            }
            // モーションデータは getCurrentMotion() で取得する
        }
    }

    func stopMonitoring() {
        guard motionManager.isDeviceMotionActive else {
            return
        }

        motionManager.stopDeviceMotionUpdates()
    }

    func getCurrentMotion() -> CMDeviceMotion? {
        return motionManager.deviceMotion
    }

    deinit {
        stopMonitoring()
    }
}
