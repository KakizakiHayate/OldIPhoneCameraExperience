//
//  ZoomIndicator.swift
//  OldIPhoneCameraExperience
//
//  Issue #41: ズームUI — iOS 4風ズーム倍率インジケーター
//

import SwiftUI

/// iOS 4風ズーム倍率インジケーター
struct ZoomIndicator: View {
    let zoomFactor: CGFloat
    let isVisible: Bool

    /// フォーマット済みズーム倍率テキスト（例: "2.5x"）
    var formattedZoom: String {
        String(format: "%.1fx", zoomFactor)
    }

    var body: some View {
        Text(formattedZoom)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.6))
            )
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(
                .easeInOut(duration: UIConstants.zoomIndicatorFadeDuration),
                value: isVisible
            )
    }
}

#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()

        VStack(spacing: 20) {
            ZoomIndicator(zoomFactor: 1.0, isVisible: true)
            ZoomIndicator(zoomFactor: 2.5, isVisible: true)
            ZoomIndicator(zoomFactor: 5.0, isVisible: true)
        }
    }
}
