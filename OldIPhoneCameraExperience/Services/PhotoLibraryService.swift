//
//  PhotoLibraryService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import Photos
import UIKit

/// フォトライブラリへの保存・権限管理を提供するプロトコル
protocol PhotoLibraryServiceProtocol {
    /// 画像をフォトライブラリに保存する
    func saveToPhotoLibrary(_ image: UIImage) async throws
    /// 動画ファイルをフォトライブラリに保存する
    func saveVideoToPhotoLibrary(_ url: URL) async throws
    /// 現在の権限状態を確認する
    func checkPermission() -> PermissionStatus
    /// 権限をリクエストする
    func requestPermission() async -> PermissionStatus
    /// 最新の写真を取得する
    func fetchLatestPhoto() async -> UIImage?
}

/// フォトライブラリへの保存の実装
final class PhotoLibraryService: PhotoLibraryServiceProtocol {
    func saveToPhotoLibrary(_ image: UIImage) async throws {
        // フォトライブラリの権限チェック
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            // 権限あり、保存処理へ
            break
        case .notDetermined:
            // 権限リクエスト
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibraryError.permissionDenied
            }
        case .denied, .restricted:
            throw PhotoLibraryError.permissionDenied
        @unknown default:
            throw PhotoLibraryError.permissionDenied
        }

        // フォトライブラリに保存
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }

    func saveVideoToPhotoLibrary(_ url: URL) async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .authorized, .limited:
            break
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized || newStatus == .limited else {
                throw PhotoLibraryError.permissionDenied
            }
        case .denied, .restricted:
            throw PhotoLibraryError.permissionDenied
        @unknown default:
            throw PhotoLibraryError.permissionDenied
        }

        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }

    func checkPermission() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestPermission() async -> PermissionStatus {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return .authorized
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func fetchLatestPhoto() async -> UIImage? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        guard let latestAsset = assets.firstObject else { return nil }

        return await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: latestAsset,
                targetSize: CGSize(width: 200, height: 200),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - PhotoLibraryError

enum PhotoLibraryError: Error {
    case permissionDenied
    case saveFailed
}
