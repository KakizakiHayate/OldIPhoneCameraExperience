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

    /// 現在のズーム倍率
    var currentZoomFactor: CGFloat { get }

    /// 録画中かどうか
    var isRecording: Bool { get }

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

    /// ズーム倍率を設定し、実際に適用された倍率を返す
    @discardableResult
    func setZoom(factor: CGFloat) -> CGFloat

    /// 動画録画を開始する
    func startRecording()

    /// 動画録画を停止し、一時ファイルURLを返す
    func stopRecording() async throws -> URL

    /// トーチ（動画用フラッシュ）のオン/オフを設定する
    func setTorch(enabled: Bool)

    /// 動画モードに切り替える
    func switchToVideoMode()

    /// 写真モードに切り替える
    func switchToPhotoMode()
}

/// カメラ操作の実装
final class CameraService: NSObject, CameraServiceProtocol {
    // MARK: - Properties

    let captureSession = AVCaptureSession()
    private var currentDevice: AVCaptureDevice?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var audioInput: AVCaptureDeviceInput?
    private var currentPosition: AVCaptureDevice.Position = CameraConfig.defaultPosition
    private var photoContinuation: CheckedContinuation<CIImage, Error>?
    private var recordingContinuation: CheckedContinuation<URL, Error>?
    private var flashMode: AVCaptureDevice.FlashMode = .off
    private var torchRequested: Bool = false
    private let sessionQueue = DispatchQueue(label: "com.oldiPhonecamera.sessionQueue")
    private let zoomLock = NSLock()
    private var _currentZoomFactor: CGFloat = CameraConfig.minZoomFactor

    var currentZoomFactor: CGFloat {
        get { zoomLock.lock(); defer { zoomLock.unlock() }; return _currentZoomFactor }
        set { zoomLock.lock(); defer { zoomLock.unlock() }; _currentZoomFactor = newValue }
    }

    private(set) var isRecording: Bool = false

    var isSessionRunning: Bool {
        captureSession.isRunning
    }

    // MARK: - CameraServiceProtocol

    func startSession() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                throw CameraError.permissionDenied
            }
        } else if status != .authorized {
            throw CameraError.permissionDenied
        }

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

        // 背面カメラ: DualWideCamera（wide + ultra-wide）を優先し、なければWideAngleにフォールバック
        // 前面カメラ: WideAngleCamera のみ（ultra-wideなし）
        let device: AVCaptureDevice?
        if currentPosition == .back {
            device = AVCaptureDevice.default(
                .builtInDualWideCamera, for: .video, position: .back
            ) ?? AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back
            )
        } else {
            device = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front
            )
        }

        guard let device else {
            captureSession.commitConfiguration()
            throw CameraError.deviceNotFound
        }
        currentDevice = device

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            captureSession.commitConfiguration()
            throw CameraError.inputFailed
        }

        let photoOut = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOut) {
            captureSession.addOutput(photoOut)
            photoOutput = photoOut
        }

        let movieOut = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(movieOut) {
            captureSession.addOutput(movieOut)
            movieFileOutput = movieOut
        }

        addAudioInputIfPermitted()

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

    @discardableResult
    func setZoom(factor: CGFloat) -> CGFloat {
        var actualFactor = factor
        sessionQueue.sync { [self] in
            guard let device = currentDevice else { return }

            let minZoom = max(CameraConfig.minZoomFactor, device.minAvailableVideoZoomFactor)
            let maxZoom = min(CameraConfig.maxZoomFactor, device.maxAvailableVideoZoomFactor)
            let clampedFactor = min(max(factor, minZoom), maxZoom)

            do {
                try device.lockForConfiguration()
                device.ramp(toVideoZoomFactor: clampedFactor, withRate: CameraConfig.zoomAnimationRate)
                device.unlockForConfiguration()
                currentZoomFactor = clampedFactor
                actualFactor = clampedFactor
            } catch {
                print("ズーム設定のためのデバイスロックに失敗しました: \(error)")
            }
        }
        return actualFactor
    }

    // MARK: - Video Recording

    func startRecording() {
        sessionQueue.async { [self] in
            guard let movieOutput = movieFileOutput, !isRecording else { return }

            let tempDir = NSTemporaryDirectory()
            let fileName = UUID().uuidString + ".mov"
            let outputURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)

            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            isRecording = true
        }
    }

    func stopRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [self] in
                guard let movieOutput = movieFileOutput, isRecording else {
                    continuation.resume(throwing: CameraError.notRecording)
                    return
                }
                recordingContinuation = continuation
                movieOutput.stopRecording()
            }
        }
    }

    func setTorch(enabled: Bool) {
        torchRequested = enabled
        sessionQueue.async { [self] in
            guard let device = currentDevice, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = enabled ? .on : .off
                device.unlockForConfiguration()
            } catch {
                // ロック取得失敗時は何もしない
            }
        }
    }

    func switchToVideoMode() {
        // セッション再構成は不要（起動時に全出力をセットアップ済み）
    }

    func switchToPhotoMode() {
        // セッション再構成は不要（起動時に全出力をセットアップ済み）
    }

    private func addAudioInputIfPermitted() {
        guard audioInput == nil else { return }

        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if audioStatus == .notDetermined {
            // sessionQueue上なので同期的にリクエスト（結果を待ってから続行）
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                semaphore.signal()
            }
            semaphore.wait()

            let newStatus = AVCaptureDevice.authorizationStatus(for: .audio)
            guard newStatus == .authorized else { return }
        } else {
            guard audioStatus == .authorized else { return }
        }

        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
        do {
            let audioIn = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioIn) {
                captureSession.addInput(audioIn)
                audioInput = audioIn
            }
        } catch {
            // マイク入力追加失敗時は音声なしで続行
        }
    }

    func switchCamera() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [self] in
                captureSession.beginConfiguration()

                let videoInput = captureSession.inputs
                    .compactMap { $0 as? AVCaptureDeviceInput }
                    .first { $0.device.hasMediaType(.video) }
                if let videoInput {
                    captureSession.removeInput(videoInput)
                }

                let newPosition: AVCaptureDevice.Position = (currentPosition == .back) ? .front : .back
                let newDevice: AVCaptureDevice?
                if newPosition == .back {
                    newDevice = AVCaptureDevice.default(
                        .builtInDualWideCamera, for: .video, position: .back
                    ) ?? AVCaptureDevice.default(
                        .builtInWideAngleCamera, for: .video, position: .back
                    )
                } else {
                    newDevice = AVCaptureDevice.default(
                        .builtInWideAngleCamera, for: .video, position: .front
                    )
                }
                guard let newDevice else {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.deviceNotFound)
                    return
                }

                do {
                    let newInput = try AVCaptureDeviceInput(device: newDevice)
                    guard captureSession.canAddInput(newInput) else {
                        captureSession.commitConfiguration()
                        continuation.resume(throwing: CameraError.inputFailed)
                        return
                    }
                    captureSession.addInput(newInput)
                    currentDevice = newDevice
                    currentPosition = newPosition
                } catch {
                    captureSession.commitConfiguration()
                    continuation.resume(throwing: CameraError.inputFailed)
                    return
                }

                self.currentZoomFactor = 1.0
                self.torchRequested = false
                captureSession.commitConfiguration()
                continuation.resume()
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from _: [AVCaptureConnection],
        error: Error?
    ) {
        isRecording = false

        // 録画終了時にトーチをオフ
        setTorch(enabled: false)

        if let error = error {
            recordingContinuation?.resume(throwing: error)
        } else {
            recordingContinuation?.resume(returning: outputFileURL)
        }
        recordingContinuation = nil
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

        guard let data = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: data)
        else {
            photoContinuation?.resume(throwing: CameraError.imageProcessingFailed)
            photoContinuation = nil
            return
        }

        let orientedImage: CIImage
        if let orientationValue = ciImage.properties[kCGImagePropertyOrientation as String] as? UInt32,
           let orientation = CGImagePropertyOrientation(rawValue: orientationValue)
        {
            orientedImage = ciImage.oriented(orientation)
        } else {
            orientedImage = ciImage
        }

        photoContinuation?.resume(returning: orientedImage)
        photoContinuation = nil
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
    case notRecording
}
