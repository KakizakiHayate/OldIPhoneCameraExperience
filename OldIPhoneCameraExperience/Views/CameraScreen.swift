//
//  CameraScreen.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import SwiftUI

/// カメラ画面（メイン画面）
struct CameraScreen: View {
    @StateObject private var viewModel: CameraViewModel
    @State private var isIrisAnimating = false
    @State private var lastCapturedImage: UIImage?

    init(
        cameraService: CameraServiceProtocol = CameraService(),
        filterService: FilterServiceProtocol = FilterService(),
        photoLibraryService: PhotoLibraryServiceProtocol = PhotoLibraryService(),
        motionService: MotionServiceProtocol = MotionService()
    ) {
        _viewModel = StateObject(wrappedValue: CameraViewModel(
            cameraService: cameraService,
            filterService: filterService,
            photoLibraryService: photoLibraryService,
            motionService: motionService
        ))
    }

    var body: some View {
        ZStack {
            // 背景: 黒
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // トップツールバー
                topToolbar
                    .frame(height: UIConstants.topToolbarHeight)

                Spacer()

                // カメラプレビュー（実装は後で追加）
                cameraPreview
                    .aspectRatio(CameraConfig.previewAspectRatio, contentMode: .fit)

                Spacer()

                // ボトムツールバー
                bottomToolbar
                    .frame(height: UIConstants.bottomToolbarHeight)
            }

            // 虹彩絞りアニメーション
            IrisAnimationView(isAnimating: $isIrisAnimating)
        }
        .statusBar(hidden: true) // レトロUI没入体験のためステータスバーを非表示
        .task {
            do {
                try await viewModel.startCamera()
            } catch {
                print("Failed to start camera: \(error)")
            }
        }
        .onDisappear {
            viewModel.stopCamera()
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            Spacer()

            // フラッシュボタン
            ToolbarButton(
                icon: "bolt.fill",
                isActive: viewModel.state.isFlashOn
            ) {
                viewModel.toggleFlash()
            }
            .padding(.trailing, 16)
        }
        .padding(.horizontal, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(white: 0.2),
                    Color(white: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Camera Preview

    private var cameraPreview: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Text("Camera Preview")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.title2)
            )
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            // サムネイル
            ThumbnailView(image: lastCapturedImage)
                .padding(.leading, 16)

            Spacer()

            // シャッターボタン
            ShutterButton(
                action: {
                    Task {
                        await capturePhoto()
                    }
                },
                isCapturing: viewModel.state.isCapturing
            )

            Spacer()

            // カメラ切り替えボタン
            ToolbarButton(icon: "arrow.triangle.2.circlepath.camera") {
                Task {
                    try? await viewModel.switchCamera()
                }
            }
            .padding(.trailing, 16)
        }
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color(white: 0.15),
                    Color(white: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Actions

    private func capturePhoto() async {
        do {
            // 虹彩絞りアニメーション開始
            isIrisAnimating = true

            // 撮影実行
            try await viewModel.capturePhoto()

            // サムネイル更新（実際の実装では撮影した画像を取得）
            // lastCapturedImage = capturedUIImage
        } catch {
            print("Failed to capture photo: \(error)")
        }
    }
}

#Preview {
    CameraScreen()
}
