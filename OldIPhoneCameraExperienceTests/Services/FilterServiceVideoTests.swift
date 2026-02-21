//
//  FilterServiceVideoTests.swift
//  OldIPhoneCameraExperienceTests
//
//  Issue #43: 動画フィルター後処理テスト
//

import AVFoundation
@testable import OldIPhoneCameraExperience
import XCTest

final class FilterServiceVideoTests: XCTestCase {
    var sut: FilterService!

    override func setUp() {
        super.setUp()
        sut = FilterService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - T-16.1: 正常な動画ファイルにフィルターを適用

    func test_applyFilterToVideo_returnsFilteredURL() async throws {
        let inputURL = try createTestVideoFile(duration: 1.0)

        let outputURL = try await sut.applyFilterToVideo(inputURL: inputURL, config: .iPhone4)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path), "フィルター適用済み動画ファイルが存在する必要があります")
        // テスト後のクリーンアップ
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - T-16.2: フィルター適用後の動画のURLが有効

    func test_applyFilterToVideo_outputIsValidVideo() async throws {
        let inputURL = try createTestVideoFile(duration: 1.0)

        let outputURL = try await sut.applyFilterToVideo(inputURL: inputURL, config: .iPhone4)

        let asset = AVAsset(url: outputURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        XCTAssertFalse(tracks.isEmpty, "フィルター適用済み動画にビデオトラックが含まれる必要があります")
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - T-16.3: フィルター適用後の動画の解像度

    func test_applyFilterToVideo_maintains720pResolution() async throws {
        let inputURL = try createTestVideoFile(duration: 1.0)

        let outputURL = try await sut.applyFilterToVideo(inputURL: inputURL, config: .iPhone4)

        let asset = AVAsset(url: outputURL)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        if let track = tracks.first {
            let size = try await track.load(.naturalSize)
            // 720p: 1280x720 or rotated
            let maxDim = max(size.width, size.height)
            let minDim = min(size.width, size.height)
            XCTAssertEqual(maxDim, 1280, accuracy: 2, "幅が1280pxである必要があります")
            XCTAssertEqual(minDim, 720, accuracy: 2, "高さが720pxである必要があります")
        }
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - T-16.5: 1秒の短い動画

    func test_applyFilterToVideo_shortVideo_processesNormally() async throws {
        let inputURL = try createTestVideoFile(duration: 1.0)

        let outputURL = try await sut.applyFilterToVideo(inputURL: inputURL, config: .iPhone4)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - T-16.6: 音声なし動画

    func test_applyFilterToVideo_noAudio_processesNormally() async throws {
        let inputURL = try createTestVideoFile(duration: 1.0, includeAudio: false)

        let outputURL = try await sut.applyFilterToVideo(inputURL: inputURL, config: .iPhone4)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        let asset = AVAsset(url: outputURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        XCTAssertTrue(audioTracks.isEmpty, "音声なし動画は音声トラックがない必要があります")
        try? FileManager.default.removeItem(at: inputURL)
        try? FileManager.default.removeItem(at: outputURL)
    }

    // MARK: - T-16.9: 存在しないURL

    func test_applyFilterToVideo_invalidURL_throws() async {
        let invalidURL = URL(fileURLWithPath: "/nonexistent/video.mov")

        do {
            _ = try await sut.applyFilterToVideo(inputURL: invalidURL, config: .iPhone4)
            XCTFail("存在しないURLでエラーがスローされる必要があります")
        } catch {
            XCTAssertTrue(error is FilterServiceError, "FilterServiceErrorがスローされる必要があります")
        }
    }

    // MARK: - T-16.11: isProcessingVideo状態

    func test_isProcessingVideo_initiallyFalse() {
        XCTAssertFalse(sut.isProcessingVideo, "初期状態ではisProcessingVideoはfalseである必要があります")
    }

    // MARK: - Helper: テスト用動画ファイルを生成

    private func createTestVideoFile(duration: Double, includeAudio _: Bool = true) throws -> URL {
        let tempDir = NSTemporaryDirectory()
        let fileName = UUID().uuidString + ".mov"
        let outputURL = URL(fileURLWithPath: tempDir).appendingPathComponent(fileName)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let (videoInput, adaptor) = makeVideoInput()
        writer.add(videoInput)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        writeBlankFrames(adaptor: adaptor, videoInput: videoInput, duration: duration)

        videoInput.markAsFinished()
        let semaphore = DispatchSemaphore(value: 0)
        writer.finishWriting { semaphore.signal() }
        semaphore.wait()

        return outputURL
    }

    private func makeVideoInput() -> (AVAssetWriterInput, AVAssetWriterInputPixelBufferAdaptor) {
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1280,
            AVVideoHeightKey: 720
        ]
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 1280,
                kCVPixelBufferHeightKey as String: 720
            ]
        )
        return (videoInput, adaptor)
    }

    private func writeBlankFrames(
        adaptor: AVAssetWriterInputPixelBufferAdaptor,
        videoInput: AVAssetWriterInput,
        duration: Double
    ) {
        let fps = 30
        let totalFrames = Int(duration * Double(fps))
        for frame in 0 ..< totalFrames {
            while !videoInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(nil, 1280, 720, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
            if let buffer = pixelBuffer {
                let time = CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps))
                adaptor.append(buffer, withPresentationTime: time)
            }
        }
    }
}
