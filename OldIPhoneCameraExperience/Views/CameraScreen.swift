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
    @State private var showEditor = false
    @State private var displayedAspectRatio: CGFloat = CameraConfig.defaultAspectRatio.portraitRatio

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
                topToolbar
                    .frame(height: UIConstants.topToolbarHeight)

                // 黒帯（上）: 写真モードのみ表示
                if isPhotoMode {
                    Spacer(minLength: 0)
                }

                // カメラプレビュー（常に1インスタンス、破棄されない）
                ZStack(alignment: .bottom) {
                    cameraPreview
                        .aspectRatio(displayedAspectRatio, contentMode: .fit)

                    ZoomIndicator(
                        zoomFactor: viewModel.zoomFactor,
                        isVisible: isZoomIndicatorVisible
                    )
                    .padding(.bottom, 16)
                    .allowsHitTesting(false)
                }
                .gesture(pinchGesture)
                .simultaneousGesture(swipeGesture)

                // 黒帯（下）: 写真モードのみ表示
                if isPhotoMode {
                    Spacer(minLength: 0)
                }

                zoomPresetButtons
                    .padding(.bottom, 12)

                shutterRow

                modeSwitchLabel
                    .padding(.vertical, 8)
            }
            .onChange(of: viewModel.captureMode) { _, _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedAspectRatio = previewAspectRatio
                }
            }
            .onChange(of: viewModel.aspectRatio) { _, _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayedAspectRatio = previewAspectRatio
                }
            }

            // 虹彩絞りアニメーション
            IrisAnimationView(isAnimating: $isIrisAnimating)
        }
        .alert("エラー", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showEditor) {
            if let image = viewModel.lastCapturedImage {
                PhotoEditorScreen(sourceImage: image)
            }
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

    // MARK: - Mode Helpers

    private var isPhotoMode: Bool {
        viewModel.captureMode == .photo
    }

    private var previewAspectRatio: CGFloat {
        if isPhotoMode {
            return viewModel.aspectRatio.portraitRatio
        }
        return 1.0 / CameraConfig.videoAspectRatio
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
                if value.translation.width < -50 {
                    viewModel.switchToVideoMode()
                } else if value.translation.width > 50 {
                    viewModel.switchToPhotoMode()
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

    // MARK: - Top Toolbar

    private var topToolbar: some View {
        HStack {
            if viewModel.captureMode == .photo {
                // 写真モード: アスペクト比ボタン（左）
                ToolbarButton(text: viewModel.aspectRatio.displayLabel) {
                    viewModel.setAspectRatio(viewModel.aspectRatio.next())
                }
                .padding(.leading, 16)
            } else {
                // ビデオモード: 「HD」「30」バッジ（左）
                videoInfoBadges
                    .padding(.leading, 16)
            }

            Spacer()

            modelSelector
                .disabled(viewModel.isRecording)
                .opacity(viewModel.isRecording ? 0.4 : 1.0)

            Spacer()

            if !viewModel.shouldHideFlashButton {
                ToolbarButton(
                    icon: viewModel.flashIconName,
                    isActive: viewModel.state.isFlashOn
                ) {
                    viewModel.toggleFlash()
                }
                .padding(.trailing, 16)
                .transition(.opacity)
            }
        }
        .background(viewModel.captureMode == .photo ? Color.black : Color.clear)
    }

    // MARK: - Model Selector

    private var modelSelector: some View {
        Menu {
            ForEach(CameraModel.allModels, id: \.name) { model in
                Button {
                    viewModel.selectModel(model)
                } label: {
                    if model == viewModel.currentModel {
                        Label(model.name, systemImage: "checkmark")
                    } else {
                        Text(model.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.currentModel.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
        }
    }

    // MARK: - Video Info Badges

    private var videoInfoBadges: some View {
        HStack(spacing: 6) {
            videoBadge("HD")
            videoBadge("30")
        }
    }

    private func videoBadge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.yellow)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.15))
            )
    }

    // MARK: - Zoom Preset Buttons

    private var zoomPresetButtons: some View {
        HStack(spacing: 12) {
            zoomPresetButton(label: "0.5", factor: 1.0)
            zoomPresetButton(label: "1x", factor: 2.0)
        }
    }

    private func zoomPresetButton(label: String, factor: CGFloat) -> some View {
        let isSelected = abs(viewModel.zoomFactor - factor) < 0.05
        return Button {
            viewModel.setZoom(factor: factor)
            baseZoomFactor = viewModel.zoomFactor
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .yellow : .white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.4))
                )
        }
    }

    // MARK: - Mode Switch Label

    private var modeSwitchLabel: some View {
        Group {
            if viewModel.isRecording {
                recordingIndicator
            } else {
                HStack(spacing: 24) {
                    modeLabel("ビデオ", isSelected: viewModel.captureMode == .video) {
                        viewModel.switchToVideoMode()
                    }
                    modeLabel("写真", isSelected: viewModel.captureMode == .photo) {
                        viewModel.switchToPhotoMode()
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

    // MARK: - Camera Preview

    private var cameraPreview: some View {
        CameraPreviewView(session: viewModel.captureSession)
            .background(Color.black)
    }

    // MARK: - Shutter Row

    private var shutterRow: some View {
        HStack {
            ThumbnailView(image: viewModel.lastCapturedImage)
                .onTapGesture {
                    if viewModel.lastCapturedImage != nil {
                        showEditor = true
                    }
                }
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
