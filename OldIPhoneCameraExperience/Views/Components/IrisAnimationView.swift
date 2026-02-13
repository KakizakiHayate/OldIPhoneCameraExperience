//
//  IrisAnimationView.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// 虹彩絞りシャッター演出（iOS 4〜6風）
struct IrisAnimationView: View {
    @Binding var isAnimating: Bool

    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // 黒い円（虹彩絞り）
            Circle()
                .fill(Color.black)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .allowsHitTesting(false)
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                performIrisAnimation()
            }
        }
    }

    private func performIrisAnimation() {
        // 初期状態: 画面全体を覆う大きな円
        scale = 1.0
        opacity = 0.0

        // 閉じるアニメーション（虹彩が中心に向かって縮む）
        withAnimation(.easeIn(duration: UIConstants.irisCloseDuration)) {
            scale = 0.0
            opacity = 1.0
        }

        // 開くアニメーション（虹彩が中心から広がって消える）
        DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.irisCloseDuration) {
            withAnimation(.easeOut(duration: UIConstants.irisOpenDuration)) {
                scale = 1.0
                opacity = 0.0
            }

            // アニメーション完了
            DispatchQueue.main.asyncAfter(deadline: .now() + UIConstants.irisOpenDuration) {
                isAnimating = false
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isAnimating = false

        var body: some View {
            ZStack {
                Color.gray
                    .ignoresSafeArea()

                VStack {
                    Button("Trigger Animation") {
                        isAnimating = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                IrisAnimationView(isAnimating: $isAnimating)
            }
        }
    }

    return PreviewWrapper()
}
