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
    @State private var baseZoomFactor: CGFloat = 1.0
    @State private var isZoomIndicatorVisible = false
    @State private var zoomFadeTask: Task<Void, Never>?
    @State private var recordingIndicatorOpacity: Double = 1.0
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

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
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // トップツールバー
                topToolbar
                    .frame(height: UIConstants.topToolbarHeight)

                Spacer()

                // カメラプレビュー + ズームインジケーター
                ZStack(alignment: .bottom) {
                    cameraPreview
                        .aspectRatio(previewAspectRatio, contentMode: .fit)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.aspectRatio)

                    ZoomIndicator(
                        zoomFactor: viewModel.zoomFactor,
                        isVisible: isZoomIndicatorVisible
                    )
                    .padding(.bottom, 16)
                    .allowsHitTesting(false)
                }
                .gesture(pinchGesture)

                // モード切替ラベル
                modeSwitchLabel
                    .padding(.vertical, 8)
                    .gesture(swipeGesture)

                Spacer()

                // ボトムツールバー
                bottomToolbar
                    .frame(height: UIConstants.bottomToolbarHeight)
            }

            // 虹彩絞りアニメーション
            IrisAnimationView(isAnimating: $isIrisAnimating)
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .statusBar(hidden: true)
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

    // MARK: - Preview Aspect Ratio

    private var previewAspectRatio: CGFloat {
        if viewModel.captureMode == .video {
            return 1.0 / CameraConfig.videoAspectRatio
        }
        return viewModel.aspectRatio.portraitRatio
    }

    // MARK: - Pinch Gesture

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let newZoom = baseZoomFactor * scale
                viewModel.setZoom(factor: newZoom)
                showZoomIndicator()
            }
            .onEnded { _ in
                baseZoomFactor = viewModel.zoomFactor
                scheduleZoomIndicatorFade()
            }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                guard !viewModel.isRecording else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    if value.translation.width < -50 {
                        viewModel.switchToVideoMode()
                    } else if value.translation.width > 50 {
                        viewModel.switchToPhotoMode()
                    }
                }
            }
    }

    // MARK: - Zoom Indicator Control

    private func showZoomIndicator() {
        zoomFadeTask?.cancel()
        withAnimation {
            isZoomIndicatorVisible = true
        }
    }

    private func scheduleZoomIndicatorFade() {
        zoomFadeTask?.cancel()
        zoomFadeTask = Task {
            try? await Task.sleep(for: .seconds(UIConstants.zoomIndicatorFadeDelay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: UIConstants.zoomIndicatorFadeDuration)) {
                isZoomIndicatorVisible = false
            }
        }
    }

    // MARK: - Mode Switch Label

    private var modeSwitchLabel: some View {
        Group {
            if viewModel.isRecording {
                recordingIndicator
            } else {
                HStack(spacing: 24) {
                    modeLabel("写真", isSelected: viewModel.captureMode == .photo) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.switchToPhotoMode()
                        }
                    }
                    modeLabel("ビデオ", isSelected: viewModel.captureMode == .video) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.switchToVideoMode()
                        }
                    }
                }
            }
        }
    }

    private func modeLabel(_ text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .yellow : .white.opacity(0.6))
        }
    }

    // MARK: - Recording Indicator

    private var recordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(recordingIndicatorOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        recordingIndicatorOpacity = 0.3
                    }
                }
                .onDisappear {
                    recordingIndicatorOpacity = 1.0
                }

            Text(viewModel.formattedRecordingDuration)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
        }
    }

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            // アスペクト比切替ボタン（写真モード時のみ表示）
            if viewModel.captureMode == .photo {
                ToolbarButton(text: viewModel.aspectRatio.displayLabel) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.setAspectRatio(viewModel.aspectRatio.next())
                    }
                }
                .padding(.leading, 16)
            }

            Spacer()

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
        CameraPreviewView(session: viewModel.captureSession)
            .background(Color.black)
    }

    // MARK: - Bottom Toolbar

    private var bottomToolbar: some View {
        HStack {
            ThumbnailView(image: viewModel.lastCapturedImage)
                .padding(.leading, 16)

            Spacer()

            ShutterButton(
                action: {
                    Task {
                        await handleShutterTap()
                    }
                },
                isCapturing: viewModel.state.isCapturing,
                captureMode: viewModel.captureMode,
                isRecording: viewModel.isRecording,
                isDisabled: viewModel.isProcessingVideo
            )

            Spacer()

            ToolbarButton(icon: "arrow.triangle.2.circlepath.camera") {
                Task {
                    try? await viewModel.switchCamera()
                }
            }
            .opacity(viewModel.isRecording ? 0.3 : 1.0)
            .disabled(viewModel.isRecording)
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

    private func handleShutterTap() async {
        if viewModel.captureMode == .video {
            if viewModel.isRecording {
                do {
                    try await viewModel.stopRecording()
                } catch {
                    errorMessage = "録画の保存に失敗しました"
                    showErrorAlert = true
                }
            } else {
                viewModel.startRecording()
            }
        } else {
            await capturePhoto()
        }
    }

    private func capturePhoto() async {
        do {
            isIrisAnimating = true
            try await viewModel.capturePhoto()
        } catch {
            print("Failed to capture photo: \(error)")
        }
    }
}

#Preview {
    CameraScreen()
}
