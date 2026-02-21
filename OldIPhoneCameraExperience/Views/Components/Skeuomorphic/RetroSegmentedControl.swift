//
//  RetroSegmentedControl.swift
//  OldIPhoneCameraExperience
//
//  Issue #50: レトロ風セグメントコントロール
//

import SwiftUI

/// iOS 4〜6風のセグメントコントロール
struct RetroSegmentedControl: View {
    @Binding var selectedTab: EditorTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(EditorTab.allCases.enumerated()), id: \.offset) { index, tab in
                if index > 0 {
                    // ディバイダー
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 1)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.displayLabel)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(segmentBackground(isSelected: selectedTab == tab))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 40)
        .frame(height: 36)
    }

    private func segmentBackground(isSelected: Bool) -> some View {
        LinearGradient(
            colors: isSelected
                ? [Color(white: 0.6), Color(white: 0.4)]
                : [Color(white: 0.27), Color(white: 0.13)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
