//
//  CameraService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import CoreImage
import UIKit

/// カメラ操作を提供するプロトコル
protocol CameraServiceProtocol {
    /// カメラセッション（プレビュー用）
    var captureSession: AVCaptureSession { get }
    
    /// カメラセッションの状態
    var isSessionRunning: Bool { get }

    /// カメラセッションを開始する
    func startSession() async throws

    /// カメラセッションを停止する
    func stopSession()

    /// 写真をキャプチャする
    func capturePhoto() async throws -> CIImage

    /// フラッシュのオン/オフを設定する
    func setFlash(enabled: Bool)

    /// 前面/背面カメラを切り替える
    func switchCamera() async throws
}

/// カメラ操作の実装
final class CameraService: NSObject, CameraServiceProtocol {

    // MARK: - Properties

    let captureSession = AVCaptureSession()
    private var currentDevice: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var currentPosition: AVCaptureDevice.Position = CameraConfig.defaultPosition
    private var photoContinuation: CheckedContinuation<CIImage, Error>?
    private let videoDataOutputQueue = DispatchQueue(label: "com.oldiPhonecamera.videoDataOutput")

    var isSessionRunning: Bool {
        captureSession.isRunning
    }

    // MARK: - CameraServiceProtocol

    func startSession() async throws {
        // カメラ権限チェック
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            if status == .notDetermined {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                guard granted else {
                    throw CameraError.permissionDenied
                }
            } else {
                throw CameraError.permissionDenied
            }
        }

        // セッション構成
        captureSession.beginConfiguration()
        captureSession.sessionPreset = CameraConfig.sessionPreset

        // デバイス取得
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentPosition) else {
            captureSession.commitConfiguration()
            throw CameraError.deviceNotFound
        }
        currentDevice = device

        // 入力追加
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            captureSession.commitConfiguration()
            throw CameraError.inputFailed
        }

        // 写真出力追加
        let photoOut = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOut) {
            captureSession.addOutput(photoOut)
            photoOutput = photoOut
        }

        // ビデオデータ出力追加（リアルタイムプレビュー用）
        let videoOut = AVCaptureVideoDataOutput()
        videoOut.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        if captureSession.canAddOutput(videoOut) {
            captureSession.addOutput(videoOut)
            videoDataOutput = videoOut
        }

        captureSession.commitConfiguration()

        // セッション開始
        await MainActor.run {
            captureSession.startRunning()
        }
    }

    func stopSession() {
        captureSession.stopRunning()
    }

    func capturePhoto() async throws -> CIImage {
        guard let photoOutput = photoOutput else {
            throw CameraError.outputNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            settings.flashMode = currentDevice?.hasFlash == true && currentDevice?.isFlashAvailable == true ? .auto : .off
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func setFlash(enabled: Bool) {
        guard let device = currentDevice, device.hasFlash else {
            return
        }

        do {
            try device.lockForConfiguration()
            if device.isTorchModeSupported(enabled ? .on : .off) {
                device.torchMode = enabled ? .on : .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Failed to set flash: \(error)")
        }
    }

    func switchCamera() async throws {
        captureSession.beginConfiguration()

        // 現在の入力を削除
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }

        // 反対側のカメラを取得
        let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.commitConfiguration()
            throw CameraError.deviceNotFound
        }

        // 新しい入力を追加
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentDevice = newDevice
                currentPosition = newPosition
            }
        } catch {
            captureSession.commitConfiguration()
            throw CameraError.inputFailed
        }

        captureSession.commitConfiguration()
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let uiImage = UIImage(data: imageData),
              let ciImage = CIImage(image: uiImage) else {
            photoContinuation?.resume(throwing: CameraError.imageProcessingFailed)
            photoContinuation = nil
            return
        }

        photoContinuation?.resume(returning: ciImage)
        photoContinuation = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // ここでフレームコールバックを通知する（Phase 2で実装予定）
        // 現時点ではフレームを取得するだけ
    }
}

// MARK: - CameraError

enum CameraError: Error {
    case permissionDenied
    case deviceNotFound
    case inputFailed
    case outputNotFound
    case imageProcessingFailed
}
