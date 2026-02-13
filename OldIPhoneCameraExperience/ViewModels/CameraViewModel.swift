//
//  CameraViewModel.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import CoreImage
import Foundation
import SwiftUI

/// カメラ画面のViewModel
@MainActor
final class CameraViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var state: CameraState
    @Published private(set) var lastCapturedImage: UIImage?

    // MARK: - Dependencies

    private let cameraService: CameraServiceProtocol
    private let filterService: FilterServiceProtocol
    private let photoLibraryService: PhotoLibraryServiceProtocol
    private let motionService: MotionServiceProtocol

    // MARK: - Private Properties

    private let currentModel: CameraModel = .iPhone4
    private let ciContext = CIContext()

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
        cameraService.setFlash(enabled: state.isFlashOn)
    }

    /// 前面/背面カメラを切り替える
    func switchCamera() async throws {
        try await cameraService.switchCamera()
        state.cameraPosition = (state.cameraPosition == .back) ? .front : .back
        // 前面カメラにはフラッシュがないため、自動的にオフにする
        if state.cameraPosition == .front, state.isFlashOn {
            state.isFlashOn = false
            cameraService.setFlash(enabled: false)
        }
    }

    /// 写真を撮影する
    func capturePhoto() async throws {
        state.isCapturing = true

        do {
            // 1. カメラから写真をキャプチャ
            let rawImage = try await cameraService.capturePhoto()

            // 2. フィルターを適用
            guard let filteredImage = filterService.applyFilters(rawImage, config: currentModel.filterConfig) else {
                throw CameraViewModelError.filterFailed
            }

            // 3. 手ブレシミュレーションを適用
            let motion = motionService.getCurrentMotion()
            let shakeEffect = ShakeEffect.generate(from: motion)
            let finalImage = filterService.applyShakeEffect(filteredImage, effect: shakeEffect) ?? filteredImage

            // 4. CIImage → UIImage 変換
            guard let uiImage = convertToUIImage(finalImage) else {
                throw CameraViewModelError.imageConversionFailed
            }

            // 5. フォトライブラリに保存
            try await photoLibraryService.saveToPhotoLibrary(uiImage)

            // 6. 直近撮影画像を更新
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
}

// MARK: - CameraViewModelError

enum CameraViewModelError: Error {
    case filterFailed
    case imageConversionFailed
}
