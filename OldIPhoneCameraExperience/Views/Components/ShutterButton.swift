//
//  ShutterButton.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// シャッターボタン（iOS 4〜6風のスキューモーフィズムデザイン）
struct ShutterButton: View {
    let action: () -> Void
    let isCapturing: Bool

    var body: some View {
        Button(action: action) {
            ZStack {
                // 外側の円（グレーのリング）
                Circle()
                    .strokeBorder(Color.white.opacity(0.8), lineWidth: 4)
                    .frame(width: UIConstants.shutterButtonSize, height: UIConstants.shutterButtonSize)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )

                // 内側の円（白い撮影ボタン）
                Circle()
                    .fill(isCapturing ? Color.gray : Color.white)
                    .frame(width: UIConstants.shutterButtonInnerSize, height: UIConstants.shutterButtonInnerSize)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
        }
        .disabled(isCapturing)
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            ShutterButton(action: {}, isCapturing: false)
            ShutterButton(action: {}, isCapturing: true)
        }
    }
}
