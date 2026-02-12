//
//  ShakeEffect.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation
import CoreMotion

/// 手ブレシミュレーションの1回分のパラメータを表すモデル
struct ShakeEffect {
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
    /// - Parameter deviceMotion: CoreMotionから取得したデバイスの動き（nilの場合はランダム生成）
    /// - Returns: ランダム要素を含む手ブレパラメータ
    static func generate(from deviceMotion: CMDeviceMotion?) -> ShakeEffect {
        let shiftRange = FilterParameters.shakeShiftRange
        let rotationRange = FilterParameters.shakeRotationRange
        let blurRange = FilterParameters.motionBlurRadiusRange

        let shiftX = Double.random(in: Double(shiftRange.lowerBound)...Double(shiftRange.upperBound))
        let shiftY = Double.random(in: Double(shiftRange.lowerBound)...Double(shiftRange.upperBound))
        let rotation = Double.random(in: Double(rotationRange.lowerBound)...Double(rotationRange.upperBound))
        let motionBlurRadius = Double.random(in: Double(blurRange.lowerBound)...Double(blurRange.upperBound))

        // ジャイロデータからブレ角度を算出（nilの場合はランダム）
        let motionBlurAngle: Double
        if let motion = deviceMotion {
            motionBlurAngle = atan2(motion.rotationRate.y, motion.rotationRate.x) * 180 / .pi
        } else {
            motionBlurAngle = Double.random(in: 0...360)
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
