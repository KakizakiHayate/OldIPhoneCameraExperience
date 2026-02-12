//
//  CameraViewModel.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Foundation
import SwiftUI
import CoreImage
import AVFoundation

/// カメラ画面のViewModel
@MainActor
final class CameraViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: CameraState
    
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
        self.state = CameraState()
    }

    // MARK: - Public Methods

    /// カメラセッションを開始する
    func startCamera() async throws {
        do {
            try await cameraService.startSession()
            motionService.startMonitoring()
            updateState { state in
                state = CameraState(
                    isFlashOn: state.isFlashOn,
                    cameraPosition: state.cameraPosition,
                    isCapturing: state.isCapturing,
                    permissionStatus: .authorized
                )
            }
        } catch {
            updateState { state in
                state = CameraState(
                    isFlashOn: state.isFlashOn,
                    cameraPosition: state.cameraPosition,
                    isCapturing: state.isCapturing,
                    permissionStatus: .denied
                )
            }
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
        let newFlashState = !state.isFlashOn
        cameraService.setFlash(enabled: newFlashState)
        updateState { state in
            state = CameraState(
                isFlashOn: newFlashState,
                cameraPosition: state.cameraPosition,
                isCapturing: state.isCapturing,
                permissionStatus: state.permissionStatus
            )
        }
    }

    /// 前面/背面カメラを切り替える
    func switchCamera() async throws {
        try await cameraService.switchCamera()
        let newPosition: CameraPosition = (state.cameraPosition == .back) ? .front : .back
        updateState { state in
            state = CameraState(
                isFlashOn: state.isFlashOn,
                cameraPosition: newPosition,
                isCapturing: state.isCapturing,
                permissionStatus: state.permissionStatus
            )
        }
    }

    /// 写真を撮影する
    func capturePhoto() async throws {
        // 撮影中フラグを立てる
        updateState { state in
            state = CameraState(
                isFlashOn: state.isFlashOn,
                cameraPosition: state.cameraPosition,
                isCapturing: true,
                permissionStatus: state.permissionStatus
            )
        }

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
            let finalImage = applyShakeEffect(to: filteredImage, effect: shakeEffect)

            // 4. CIImage → UIImage 変換
            guard let uiImage = convertToUIImage(finalImage) else {
                throw CameraViewModelError.imageConversionFailed
            }

            // 5. フォトライブラリに保存
            try await photoLibraryService.saveToPhotoLibrary(uiImage)

            // 撮影完了
            updateState { state in
                state = CameraState(
                    isFlashOn: state.isFlashOn,
                    cameraPosition: state.cameraPosition,
                    isCapturing: false,
                    permissionStatus: state.permissionStatus
                )
            }
        } catch {
            // エラー時も撮影中フラグを下ろす
            updateState { state in
                state = CameraState(
                    isFlashOn: state.isFlashOn,
                    cameraPosition: state.cameraPosition,
                    isCapturing: false,
                    permissionStatus: state.permissionStatus
                )
            }
            throw error
        }
    }

    // MARK: - Private Methods

    private func updateState(_ update: (inout CameraState) -> Void) {
        var newState = state
        update(&newState)
        state = newState
    }

    private func applyShakeEffect(to image: CIImage, effect: ShakeEffect) -> CIImage {
        var outputImage = image

        // 1. シフト（平行移動）
        let shiftTransform = CGAffineTransform(translationX: effect.shiftX, y: effect.shiftY)
        outputImage = outputImage.transformed(by: shiftTransform)

        // 2. 回転
        let rotationRadians = effect.rotation * .pi / 180.0
        let rotationTransform = CGAffineTransform(rotationAngle: rotationRadians)
        outputImage = outputImage.transformed(by: rotationTransform)

        // 3. モーションブラー
        if let motionBlurFilter = CIFilter(name: "CIMotionBlur") {
            motionBlurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            motionBlurFilter.setValue(effect.motionBlurRadius, forKey: kCIInputRadiusKey)
            motionBlurFilter.setValue(effect.motionBlurAngle * .pi / 180.0, forKey: kCIInputAngleKey)
            if let result = motionBlurFilter.outputImage {
                outputImage = result
            }
        }

        return outputImage
    }

    private func convertToUIImage(_ ciImage: CIImage) -> UIImage? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
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
