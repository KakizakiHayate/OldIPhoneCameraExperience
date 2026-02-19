//
//  PhotoEditorScreen.swift
//  OldIPhoneCameraExperience
//
//  Issue #50: 写真編集画面（レトロ風スキューモーフィズム）
//

import SwiftUI

/// 写真編集画面
struct PhotoEditorScreen: View {
    @StateObject private var viewModel: PhotoEditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(sourceImage: UIImage) {
        _viewModel = StateObject(wrappedValue: PhotoEditorViewModel(sourceImage: sourceImage))
    }

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダーバー
            headerBar

            // 画像プレビュー
            previewArea
                .frame(maxHeight: .infinity)

            // セグメントコントロール
            RetroSegmentedControl(selectedTab: $viewModel.selectedTab)
                .padding(.vertical, 12)

            // コントロール部分
            controlsArea
                .frame(height: 200)
                .padding(.bottom, 20)
        }
        .background(Color.black)
        .statusBar(hidden: true)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button("キャンセル") {
                dismiss()
            }
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.leading, 16)

            Spacer()

            Button("保存") {
                Task {
                    try? await viewModel.saveEditedPhoto()
                    dismiss()
                }
            }
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(viewModel.isSaving ? .gray : .white)
            .disabled(viewModel.isSaving)
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(
            LinearGradient(
                colors: [Color(white: 0.25), Color(white: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        Group {
            if let previewImage = viewModel.previewImage {
                if viewModel.selectedTab == .crop {
                    cropPreview(image: previewImage)
                } else {
                    Image(uiImage: previewImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(16)
                }
            } else {
                Color.black
            }
        }
    }

    private func cropPreview(image: UIImage) -> some View {
        GeometryReader { geometry in
            let imageSize = image.size
            let viewSize = geometry.size
            let fitScale = min(viewSize.width / imageSize.width, viewSize.height / imageSize.height)
            let displaySize = CGSize(
                width: imageSize.width * fitScale,
                height: imageSize.height * fitScale
            )
            let offset = CGSize(
                width: (viewSize.width - displaySize.width) / 2,
                height: (viewSize.height - displaySize.height) / 2
            )

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .position(x: viewSize.width / 2, y: viewSize.height / 2)

                if let cropRect = Binding($viewModel.cropRect) {
                    CropOverlayView(
                        cropRect: cropRect,
                        imageBounds: CGRect(origin: CGPoint(x: offset.width, y: offset.height), size: displaySize),
                        cropMode: viewModel.cropMode
                    )
                }
            }
            .onAppear {
                let bounds = CGRect(
                    origin: CGPoint(x: offset.width, y: offset.height),
                    size: displaySize
                )
                viewModel.imageDisplayBounds = bounds
                if viewModel.cropRect == nil {
                    viewModel.cropRect = CGRect(
                        x: bounds.origin.x + displaySize.width * 0.1,
                        y: bounds.origin.y + displaySize.height * 0.1,
                        width: displaySize.width * 0.8,
                        height: displaySize.height * 0.8
                    )
                }
            }
        }
    }

    // MARK: - Controls Area

    private var controlsArea: some View {
        Group {
            if viewModel.selectedTab == .adjust {
                adjustControls
            } else {
                cropControls
            }
        }
    }

    // MARK: - Adjust Controls

    private var adjustControls: some View {
        VStack(spacing: 16) {
            RetroSlider(
                value: $viewModel.brightness,
                range: EditorConstants.brightnessRange,
                label: "明るさ",
                iconLeft: "sun.min.fill",
                iconRight: "sun.max.fill",
                onChanged: { viewModel.onSliderChanged() }
            )

            RetroSlider(
                value: $viewModel.contrast,
                range: EditorConstants.contrastRange,
                label: "コントラスト",
                iconLeft: "circle.lefthalf.filled",
                iconRight: "circle.lefthalf.filled",
                onChanged: { viewModel.onSliderChanged() }
            )

            RetroSlider(
                value: $viewModel.saturation,
                range: EditorConstants.saturationRange,
                label: "彩度",
                iconLeft: "drop.fill",
                iconRight: "drop.fill",
                onChanged: { viewModel.onSliderChanged() }
            )
        }
    }

    // MARK: - Crop Controls

    private var cropControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                cropModeButton("自由", mode: .free)
                cropModeButton("1:1", mode: .fixed(.square))
                cropModeButton("4:3", mode: .fixed(.standard))
                cropModeButton("16:9", mode: .fixed(.wide))
            }

            Button {
                viewModel.resetAdjustments()
            } label: {
                Text("リセット")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func cropModeButton(_ label: String, mode: CropMode) -> some View {
        Button {
            viewModel.setCropMode(mode)
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(cropModeGradient(isSelected: viewModel.cropMode == mode))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        }
    }

    private func cropModeGradient(isSelected: Bool) -> LinearGradient {
        if isSelected {
            return LinearGradient(
                colors: [Color(white: 0.5), Color(white: 0.35)],
                startPoint: .top, endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [Color(white: 0.25), Color(white: 0.15)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
