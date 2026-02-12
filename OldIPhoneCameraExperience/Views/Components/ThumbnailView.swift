//
//  ThumbnailView.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// 撮影した写真のサムネイル（iOS 4〜6風のデザイン）
struct ThumbnailView: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIConstants.thumbnailSize, height: UIConstants.thumbnailSize)
                    .clipShape(RoundedRectangle(cornerRadius: UIConstants.thumbnailCornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.thumbnailCornerRadius)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: UIConstants.thumbnailCornerRadius)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: UIConstants.thumbnailSize, height: UIConstants.thumbnailSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: UIConstants.thumbnailCornerRadius)
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black
        HStack(spacing: 20) {
            ThumbnailView(image: nil)
            ThumbnailView(image: UIImage(systemName: "photo"))
        }
    }
}
