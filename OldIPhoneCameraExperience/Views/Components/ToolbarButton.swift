//
//  ToolbarButton.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// ツールバーボタン（iOS 4〜6風のスキューモーフィズムデザイン）
struct ToolbarButton: View {
    let icon: String
    let action: () -> Void
    let isActive: Bool

    init(icon: String, isActive: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景（金属質感のグラデーション）
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: isActive ? [
                                Color(white: 0.4),
                                Color(white: 0.3)
                            ] : [
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

                // アイコン
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .medium))
            }
        }
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
