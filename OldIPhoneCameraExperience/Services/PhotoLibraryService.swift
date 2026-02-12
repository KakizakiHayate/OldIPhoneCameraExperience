//
//  PhotoLibraryService.swift
//  OldIPhoneCameraExperience
//
//  Created by Manus on 2026-02-13.
//

import UIKit
import Photos

/// フォトライブラリへの保存を提供するプロトコル
protocol PhotoLibraryServiceProtocol {
    /// 画像をフォトライブラリに保存する
    func saveToPhotoLibrary(_ image: UIImage) async throws
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
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? PhotoLibraryError.saveFailed)
                }
            }
        }
    }
}

// MARK: - PhotoLibraryError

enum PhotoLibraryError: Error {
    case permissionDenied
    case saveFailed
}
