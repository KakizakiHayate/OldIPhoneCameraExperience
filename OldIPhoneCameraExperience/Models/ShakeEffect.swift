//
//  ShakeEffect.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import CoreMotion
import Foundation

/// 手ブレシミュレーションの1回分のパラメータを表すモデル
struct ShakeEffect: Equatable {
    /// X方向のシフト量（px）
    let shiftX: Double

    /// Y方向のシフト量（px）
    let shiftY: Double

    /// 回転角度（度）
    let rotation: Double

    /// モーションブラーの半径
    let motionBlurRadius: Double

    /// モーションブラーの角度（度）
    let motionBlurAngle: Double
}

// MARK: - Factory Method

extension ShakeEffect {
    /// ジャイロスコープのデータからShakeEffectを生成する
    /// - Parameters:
    ///   - deviceMotion: CoreMotionから取得したデバイスの動き（nilの場合はランダム生成）
    ///   - config: フィルター設定（手ブレパラメータを含む）
    /// - Returns: ランダム要素を含む手ブレパラメータ
    static func generate(from deviceMotion: CMDeviceMotion?, config: FilterConfig) -> ShakeEffect {
        let shiftRange = config.shakeShiftRange
        let rotationRange = config.shakeRotationRange
        let blurRange = config.motionBlurRadiusRange

        let shiftX = Double.random(in: shiftRange)
        let shiftY = Double.random(in: shiftRange)
        let rotation = Double.random(in: rotationRange)
        let motionBlurRadius = Double.random(in: blurRange)

        // ジャイロデータからブレ角度を算出（nilの場合はランダム）
        let motionBlurAngle: Double
        if let motion = deviceMotion {
            motionBlurAngle = atan2(motion.rotationRate.y, motion.rotationRate.x) * 180 / .pi
        } else {
            motionBlurAngle = Double.random(in: 0 ... 360)
        }

        return ShakeEffect(
            shiftX: shiftX,
            shiftY: shiftY,
            rotation: rotation,
            motionBlurRadius: motionBlurRadius,
            motionBlurAngle: motionBlurAngle
        )
    }
}
