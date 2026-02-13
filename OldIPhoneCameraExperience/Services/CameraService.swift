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
    private var flashMode: AVCaptureDevice.FlashMode = .off
    private let sessionQueue = DispatchQueue(label: "com.oldiPhonecamera.sessionQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "com.oldiPhonecamera.videoDataOutput")

    var isSessionRunning: Bool {
        captureSession.isRunning
    }

    // MARK: - CameraServiceProtocol

    func startSession() async throws {
        // カメラ権限チェック
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                throw CameraError.permissionDenied
            }
        } else if status != .authorized {
            throw CameraError.permissionDenied
        }

        // セッション構成・開始をシリアルキューで実行
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                do {
                    try configureSession()
                    captureSession.startRunning()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func configureSession() throws {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = CameraConfig.sessionPreset

        // デバイス取得
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera, for: .video, position: currentPosition
        ) else {
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
    }

    func stopSession() {
        sessionQueue.async { [self] in
            captureSession.stopRunning()
        }
    }

    func capturePhoto() async throws -> CIImage {
        guard photoContinuation == nil else {
            throw CameraError.captureInProgress
        }

        guard let photoOutput = photoOutput else {
            throw CameraError.outputNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            photoContinuation = continuation

            let settings = AVCapturePhotoSettings()
            if currentDevice?.hasFlash == true, currentDevice?.isFlashAvailable == true {
                settings.flashMode = flashMode
            } else {
                settings.flashMode = .off
            }
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func setFlash(enabled: Bool) {
        flashMode = enabled ? .on : .off
    }

    func switchCamera() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                captureSession.beginConfiguration()

                // 現在の入力を削除
                if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
                    captureSession.removeInput(currentInput)
                }

                // 反対側のカメラを取得
                let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
                guard let newDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: newPosition
                ) else {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.deviceNotFound)
                    return
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
                    continuation.resume(throwing: CameraError.inputFailed)
                    return
                }

                captureSession.commitConfiguration()
                continuation.resume()
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }

        guard let pixelBuffer = photo.pixelBuffer else {
            photoContinuation?.resume(throwing: CameraError.imageProcessingFailed)
            photoContinuation = nil
            return
        }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        photoContinuation?.resume(returning: ciImage)
        photoContinuation = nil
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from _: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        _ = CIImage(cvPixelBuffer: pixelBuffer)
        // ここでフレームコールバックを通知する（Phase 2で実装予定）
    }
}

// MARK: - CameraError

enum CameraError: Error {
    case permissionDenied
    case deviceNotFound
    case inputFailed
    case outputNotFound
    case imageProcessingFailed
    case captureInProgress
}
