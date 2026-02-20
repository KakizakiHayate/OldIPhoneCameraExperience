//
//  FilterService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import AVFoundation
import CoreGraphics
import CoreImage

/// フィルター処理を提供するプロトコル
protocol FilterServiceProtocol {
    /// 暖色系フィルターを適用する
    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// 画角クロップを適用する
    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// iPhone 4相当の解像度（5MP）にスケーリングする
    func applyDownscale(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// すべてのフィルターを適用する（暖色系 → スケーリング）
    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage?

    /// 手ブレシミュレーションを適用する
    func applyShakeEffect(_ image: CIImage, effect: ShakeEffect) -> CIImage?

    /// 動画ファイルに暖色フィルターを適用する
    func applyFilterToVideo(inputURL: URL, config: FilterConfig) async throws -> URL

    /// 動画フィルター処理中かどうか
    var isProcessingVideo: Bool { get }
}

/// フィルター処理の実装
final class FilterService: FilterServiceProtocol {
    private let context = CIContext()
    private(set) var isProcessingVideo: Bool = false

    // MARK: - FilterServiceProtocol

    func applyWarmthFilter(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let tintIntensity = CGFloat(config.highlightTintIntensity)

        return image
            .applyingFilter("CITemperatureAndTint", parameters: [
                "inputNeutral": CIVector(x: config.warmth, y: config.tint)
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: config.saturation
            ])
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.0 + tintIntensity, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 1.0 + tintIntensity * 0.5, z: 0, w: 0)
            ])
    }

    func applyCrop(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let inputExtent = image.extent

        // クロップ率に基づいて中央部分を切り出す（26mm→32mm画角変換）
        let cropRatio = CGFloat(config.cropRatio)
        let croppedWidth = inputExtent.width * cropRatio
        let croppedHeight = inputExtent.height * cropRatio

        let cropX = (inputExtent.width - croppedWidth) / 2
        let cropY = (inputExtent.height - croppedHeight) / 2
        let cropRect = CGRect(x: cropX, y: cropY, width: croppedWidth, height: croppedHeight)

        return image.cropped(to: cropRect)
    }

    func applyDownscale(_ image: CIImage, config: FilterConfig) -> CIImage? {
        let inputExtent = image.extent
        let targetWidth = CGFloat(config.outputWidth)
        let targetHeight = CGFloat(config.outputHeight)

        // 入力画像の向きに合わせてターゲットサイズを決定
        // 縦長画像（ポートレート）の場合はwidth/heightを入れ替える
        let isPortrait = inputExtent.height > inputExtent.width
        let finalTargetWidth = isPortrait ? min(targetWidth, targetHeight) : max(targetWidth, targetHeight)
        let finalTargetHeight = isPortrait ? max(targetWidth, targetHeight) : min(targetWidth, targetHeight)

        // 既にターゲットサイズ以下ならスケーリング不要
        if inputExtent.width <= finalTargetWidth, inputExtent.height <= finalTargetHeight {
            return image
        }

        // アスペクト比を維持しながらターゲットサイズに収まるスケール率を計算
        let scaleX = finalTargetWidth / inputExtent.width
        let scaleY = finalTargetHeight / inputExtent.height
        let scale = min(scaleX, scaleY)

        // CGAffineTransformでスケーリング（Lanczosと違いエッジアーティファクトが発生しない）
        return image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    func applyFilters(_ image: CIImage, config: FilterConfig) -> CIImage? {
        // 1. 暖色系フィルター
        guard let warmthImage = applyWarmthFilter(image, config: config) else {
            return nil
        }

        // 2. iPhone 4相当の解像度にスケーリング
        guard let outputImage = applyDownscale(warmthImage, config: config) else {
            return nil
        }

        return outputImage
    }

    // MARK: - Video Filter

    func applyFilterToVideo(inputURL: URL, config: FilterConfig) async throws -> URL {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw FilterServiceError.fileNotFound
        }

        isProcessingVideo = true
        defer { isProcessingVideo = false }

        let asset = AVAsset(url: inputURL)
        let outputURL = makeTemporaryOutputURL()

        let (reader, readerVideoOutput, readerAudioOutput) = try await configureReader(for: asset)
        let writerConfig = try await configureWriter(
            for: asset, outputURL: outputURL, hasAudio: readerAudioOutput != nil
        )

        reader.startReading()
        writerConfig.writer.startWriting()
        writerConfig.writer.startSession(atSourceTime: .zero)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                try await self.processVideoFrames(
                    readerOutput: readerVideoOutput,
                    writerAdaptor: writerConfig.pixelBufferAdaptor,
                    config: config,
                    frameSize: writerConfig.trackSize
                )
            }
            if let audioOutput = readerAudioOutput, let audioInput = writerConfig.audioInput {
                group.addTask {
                    await self.copyAudioTrack(readerOutput: audioOutput, writerInput: audioInput)
                }
            }
            try await group.waitForAll()
        }

        await writerConfig.writer.finishWriting()

        guard writerConfig.writer.status == .completed else {
            throw FilterServiceError.videoProcessingFailed
        }

        return outputURL
    }

    private func makeTemporaryOutputURL() -> URL {
        let tempDir = NSTemporaryDirectory()
        let outputFileName = UUID().uuidString + "_filtered.mov"
        return URL(fileURLWithPath: tempDir).appendingPathComponent(outputFileName)
    }

    private func configureReader(
        for asset: AVAsset
    ) async throws -> (AVAssetReader, AVAssetReaderTrackOutput, AVAssetReaderTrackOutput?) {
        let reader = try AVAssetReader(asset: asset)

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw FilterServiceError.noVideoTrack
        }

        let readerVideoSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let readerVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: readerVideoSettings)
        reader.add(readerVideoOutput)

        var readerAudioOutput: AVAssetReaderTrackOutput?
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: nil)
            reader.add(audioOutput)
            readerAudioOutput = audioOutput
        }

        return (reader, readerVideoOutput, readerAudioOutput)
    }

    private func configureWriter(
        for asset: AVAsset,
        outputURL: URL,
        hasAudio: Bool
    ) async throws -> VideoWriterConfig {
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let firstVideoTrack = videoTracks.first else {
            throw FilterServiceError.noVideoTrack
        }
        let trackSize = try await firstVideoTrack.load(.naturalSize)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: trackSize.width,
            AVVideoHeightKey: trackSize.height
        ]
        let writerVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerVideoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: Int(trackSize.width),
                kCVPixelBufferHeightKey as String: Int(trackSize.height)
            ]
        )
        writer.add(writerVideoInput)

        var writerAudioInput: AVAssetWriterInput?
        if hasAudio {
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: nil)
            writer.add(audioInput)
            writerAudioInput = audioInput
        }

        return VideoWriterConfig(
            writer: writer,
            pixelBufferAdaptor: pixelBufferAdaptor,
            audioInput: writerAudioInput,
            trackSize: trackSize
        )
    }

    private func processVideoFrames(
        readerOutput: AVAssetReaderTrackOutput,
        writerAdaptor: AVAssetWriterInputPixelBufferAdaptor,
        config: FilterConfig,
        frameSize _: CGSize
    ) async throws {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let writerInput = writerAdaptor.assetWriterInput
            let processingQueue = DispatchQueue(label: "com.oldiPhonecamera.videoProcessing")
            writerInput.requestMediaDataWhenReady(on: processingQueue) { [self] in
                while writerInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        continuation.resume()
                        return
                    }
                    let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                        continue
                    }
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    let filteredImage = applyWarmthFilter(ciImage, config: config) ?? ciImage
                    var outputBuffer: CVPixelBuffer?
                    if let pool = writerAdaptor.pixelBufferPool {
                        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &outputBuffer)
                    }
                    if let buffer = outputBuffer {
                        self.context.render(filteredImage, to: buffer)
                        if !writerAdaptor.append(buffer, withPresentationTime: presentationTime) {
                            writerInput.markAsFinished()
                            continuation.resume()
                            return
                        }
                    }
                }
            }
        }
    }

    private func copyAudioTrack(
        readerOutput: AVAssetReaderTrackOutput,
        writerInput: AVAssetWriterInput
    ) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let audioQueue = DispatchQueue(label: "com.oldiPhonecamera.audioProcessing")
            writerInput.requestMediaDataWhenReady(on: audioQueue) {
                while writerInput.isReadyForMoreMediaData {
                    guard let sampleBuffer = readerOutput.copyNextSampleBuffer() else {
                        writerInput.markAsFinished()
                        continuation.resume()
                        return
                    }
                    writerInput.append(sampleBuffer)
                }
            }
        }
    }

    func applyShakeEffect(_ image: CIImage, effect: ShakeEffect) -> CIImage? {
        let originalExtent = image.extent

        // 端ピクセルを無限に引き伸ばし、変換後のエッジに白線が出るのを防止する
        var outputImage = image.clampedToExtent()

        // 1. シフト（平行移動）+ 回転を適用し、元の範囲でクロップ
        // 写真の中身がブレて見える効果を出しつつ、写真の矩形自体は維持する
        let shiftTransform = CGAffineTransform(translationX: effect.shiftX, y: effect.shiftY)
        let rotationRadians = effect.rotation * .pi / 180.0
        let centerX = originalExtent.midX
        let centerY = originalExtent.midY
        let rotationTransform = CGAffineTransform(translationX: centerX, y: centerY)
            .rotated(by: rotationRadians)
            .translatedBy(x: -centerX, y: -centerY)
        let combined = shiftTransform.concatenating(rotationTransform)
        outputImage = outputImage.transformed(by: combined).cropped(to: originalExtent)

        // 2. モーションブラー
        if let motionBlurFilter = CIFilter(name: "CIMotionBlur") {
            motionBlurFilter.setValue(outputImage, forKey: kCIInputImageKey)
            motionBlurFilter.setValue(effect.motionBlurRadius, forKey: kCIInputRadiusKey)
            motionBlurFilter.setValue(effect.motionBlurAngle * .pi / 180.0, forKey: kCIInputAngleKey)
            if let result = motionBlurFilter.outputImage {
                outputImage = result.cropped(to: originalExtent)
            }
        }

        return outputImage
    }
}

// MARK: - VideoWriterConfig

struct VideoWriterConfig {
    let writer: AVAssetWriter
    let pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
    let audioInput: AVAssetWriterInput?
    let trackSize: CGSize
}

// MARK: - FilterServiceError

enum FilterServiceError: Error {
    case fileNotFound
    case noVideoTrack
    case videoProcessingFailed
}
