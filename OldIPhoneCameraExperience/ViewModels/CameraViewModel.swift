//
//  CameraViewModel.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import Combine
import CoreImage
import Foundation
import SwiftUI

/// カメラ画面のViewModel
@MainActor
final class CameraViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: CameraState
    @Published private(set) var lastCapturedImage: UIImage?
    @Published private(set) var zoomFactor: CGFloat = CameraConfig.minZoomFactor
    @Published private(set) var captureMode: CaptureMode = .photo
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var isProcessingVideo: Bool = false

    /// カメラセッション（プレビュー用）
    var captureSession: AVCaptureSession {
        cameraService.captureSession
    }

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private let filterService: FilterServiceProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let motionService: MotionServiceProtocol

    // MARK: - Private Properties

    private let currentModel: CameraModel = .iPhone4
    private let ciContext = CIContext()
    private var recordingTimer: AnyCancellable?

    // MARK: - Initialization

    init(
        cameraService: CameraServiceProtocol,
        filterService: FilterServiceProtocol,
        photoLibraryService: PhotoLibraryServiceProtocol,
        motionService: MotionServiceProtocol
    ) {
        self.cameraService = cameraService
        self.filterService = filterService
        self.photoLibraryService = photoLibraryService
        self.motionService = motionService
        state = CameraState()
    }

    // MARK: - Public Methods

    /// カメラセッションを開始する
    func startCamera() async throws {
        do {
            try await cameraService.startSession()
            motionService.startMonitoring()
            state.permissionStatus = .authorized
        } catch {
            state.permissionStatus = .denied
            throw error
        }
    }

    /// カメラセッションを停止する
    func stopCamera() {
        cameraService.stopSession()
        motionService.stopMonitoring()
    }

    /// フラッシュのオン/オフを切り替える
    func toggleFlash() {
        state.isFlashOn.toggle()
        if captureMode == .video {
            cameraService.setTorch(enabled: state.isFlashOn)
        } else {
            cameraService.setFlash(enabled: state.isFlashOn)
        }
    }

    /// 前面/背面カメラを切り替える
    func switchCamera() async throws {
        guard !isRecording else { return }
        try await cameraService.switchCamera()
        state.cameraPosition = (state.cameraPosition == .back) ? .front : .back
        zoomFactor = CameraConfig.minZoomFactor
        if state.cameraPosition == .front, state.isFlashOn {
            state.isFlashOn = false
            cameraService.setFlash(enabled: false)
        }
    }

    /// ズーム倍率を設定する
    func setZoom(factor: CGFloat) {
        let clamped = min(max(factor, CameraConfig.minZoomFactor), CameraConfig.maxZoomFactor)
        zoomFactor = clamped
        cameraService.setZoom(factor: clamped)
    }

    // MARK: - Mode Switching

    /// 動画モードに切り替える
    func switchToVideoMode() {
        guard captureMode != .video, !isRecording else { return }
        captureMode = .video
        cameraService.switchToVideoMode()
        if state.isFlashOn {
            cameraService.setTorch(enabled: true)
        }
    }

    /// 写真モードに切り替える
    func switchToPhotoMode() {
        guard captureMode != .photo, !isRecording else { return }
        captureMode = .photo
        cameraService.switchToPhotoMode()
        if state.isFlashOn {
            cameraService.setTorch(enabled: false)
            cameraService.setFlash(enabled: true)
        }
    }

    // MARK: - Video Recording

    /// 動画録画を開始する
    func startRecording() {
        guard captureMode == .video, !isRecording, !isProcessingVideo else { return }
        cameraService.startRecording()
        isRecording = true
        recordingDuration = 0
        startRecordingTimer()
    }

    /// 動画録画を停止し、フィルター適用後に保存する
    func stopRecording() async throws {
        guard isRecording else { return }
        stopRecordingTimer()
        isRecording = false

        let rawVideoURL = try await cameraService.stopRecording()

        isProcessingVideo = true
        do {
            let filteredURL = try await filterService.applyFilterToVideo(
                inputURL: rawVideoURL, config: currentModel.filterConfig
            )
            try await photoLibraryService.saveVideoToPhotoLibrary(filteredURL)

            // 一時ファイル削除
            try? FileManager.default.removeItem(at: rawVideoURL)
            try? FileManager.default.removeItem(at: filteredURL)

            isProcessingVideo = false
            recordingDuration = 0
        } catch {
            isProcessingVideo = false
            recordingDuration = 0
            throw error
        }
    }

    /// 写真を撮影する
    func capturePhoto() async throws {
        state.isCapturing = true

        do {
            let rawImage = try await cameraService.capturePhoto()

            guard let filteredImage = filterService.applyFilters(rawImage, config: currentModel.filterConfig) else {
                throw CameraViewModelError.filterFailed
            }

            let motion = motionService.getCurrentMotion()
            let shakeEffect = ShakeEffect.generate(from: motion)
            let finalImage = filterService.applyShakeEffect(filteredImage, effect: shakeEffect) ?? filteredImage

            guard let uiImage = convertToUIImage(finalImage) else {
                throw CameraViewModelError.imageConversionFailed
            }

            try await photoLibraryService.saveToPhotoLibrary(uiImage)
            lastCapturedImage = uiImage

            state.isCapturing = false
        } catch {
            state.isCapturing = false
            throw error
        }
    }

    // MARK: - Private Methods

    private func convertToUIImage(_ ciImage: CIImage) -> UIImage? {
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private func startRecordingTimer() {
        recordingTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recordingDuration += 1
            }
    }

    private func stopRecordingTimer() {
        recordingTimer?.cancel()
        recordingTimer = nil
    }
}

// MARK: - CameraViewModelError

enum CameraViewModelError: Error {
    case filterFailed
    case imageConversionFailed
}

// MARK: - Recording Duration Formatter

extension CameraViewModel {
    /// 録画時間をMM:SS（1時間以上はHH:MM:SS）形式でフォーマット
    var formattedRecordingDuration: String {
        let totalSeconds = Int(recordingDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
