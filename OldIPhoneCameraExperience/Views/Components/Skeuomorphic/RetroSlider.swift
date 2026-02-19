//
//  RetroSlider.swift
//  OldIPhoneCameraExperience
//
//  Issue #50: レトロ風スライダー
//

import SwiftUI

/// iOS 4〜6風のカスタムスライダー
struct RetroSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    let label: String
    let iconLeft: String
    let iconRight: String
    var onChanged: (() -> Void)?

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 20

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 8) {
                Image(systemName: iconLeft)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 16)

                GeometryReader { geometry in
                    let trackWidth = geometry.size.width
                    let normalizedValue = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let thumbX = normalizedValue * (trackWidth - thumbSize)

                    ZStack(alignment: .leading) {
                        // トラック（溝）
                        RoundedRectangle(cornerRadius: trackHeight / 2)
                            .fill(Color(white: 0.2))
                            .frame(height: trackHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: trackHeight / 2)
                                    .stroke(Color.black.opacity(0.5), lineWidth: 0.5)
                            )

                        // つまみ
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.95), Color(white: 0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: thumbSize, height: thumbSize)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                            .offset(x: thumbX)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let normalized = Float(gesture.location.x / trackWidth)
                                let clamped = min(max(normalized, 0), 1)
                                value = range.lowerBound + clamped * (range.upperBound - range.lowerBound)
                                onChanged?()
                            }
                    )
                }
                .frame(height: thumbSize)

                Image(systemName: iconRight)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 16)
            }
        }
        .padding(.horizontal, 20)
    }
}
