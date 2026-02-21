//
//  ToolbarButton.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// ツールバーボタン（iOS 4〜6風のスキューモーフィズムデザイン）
struct ToolbarButton: View {
    enum Content {
        case icon(String)
        case text(String)
    }

    let content: Content
    let isActive: Bool
    let action: () -> Void

    init(icon: String, isActive: Bool = false, action: @escaping () -> Void) {
        content = .icon(icon)
        self.isActive = isActive
        self.action = action
    }

    init(text: String, isActive: Bool = false, action: @escaping () -> Void) {
        content = .text(text)
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景（ON: 黄色、OFF: 金属質感グラデーション）
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isActive
                            ? LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.84, blue: 0.04),
                                    Color(red: 0.9, green: 0.75, blue: 0.03)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [
                                    Color(white: 0.5),
                                    Color(white: 0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                    )
                    .frame(width: 44, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                // テキストまたはアイコン
                switch content {
                case let .text(text):
                    Text(text)
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                case let .icon(icon):
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    ZStack {
        Color.black
        HStack(spacing: 20) {
            ToolbarButton(icon: "bolt.fill", isActive: false, action: {})
            ToolbarButton(icon: "bolt.fill", isActive: true, action: {})
            ToolbarButton(icon: "arrow.triangle.2.circlepath.camera", action: {})
        }
    }
}
