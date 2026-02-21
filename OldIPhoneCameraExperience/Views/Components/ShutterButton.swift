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
    var captureMode: CaptureMode = .photo
    var isRecording: Bool = false
    var isDisabled: Bool = false

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

                // 内側: モードに応じて変化
                innerButton
            }
        }
        .disabled(isCapturing || isDisabled)
        .animation(.easeInOut(duration: 0.3), value: captureMode)
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }

    @ViewBuilder
    private var innerButton: some View {
        if captureMode == .video {
            if isRecording {
                // 録画中: 赤い角丸四角（停止ボタン）
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            } else {
                // 動画モード: 赤い丸
                Circle()
                    .fill(isDisabled ? Color.gray : Color.red)
                    .frame(
                        width: UIConstants.shutterButtonInnerSize,
                        height: UIConstants.shutterButtonInnerSize
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
        } else {
            // 写真モード: 白い丸
            Circle()
                .fill(isCapturing ? Color.gray : Color.white)
                .frame(
                    width: UIConstants.shutterButtonInnerSize,
                    height: UIConstants.shutterButtonInnerSize
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VStack(spacing: 40) {
            ShutterButton(action: {}, isCapturing: false)
            ShutterButton(action: {}, isCapturing: false, captureMode: .video)
            ShutterButton(action: {}, isCapturing: false, captureMode: .video, isRecording: true)
        }
    }
}
