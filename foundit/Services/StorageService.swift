//
//  StorageService.swift
//  foundit
//

import Foundation
import FirebaseStorage

class StorageService {
    private let storage = Storage.storage()

    func uploadImage(data: Data, path: String) async throws -> String {
        let ref = storage.reference().child(path)
        _ = try await ref.putDataAsync(data)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }

    func uploadImages(dataArray: [Data], postId: String) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self) { group in
            for (index, data) in dataArray.enumerated() {
                group.addTask {
                    let path = "posts/\(postId)/\(UUID().uuidString)_\(index).jpg"
                    return try await self.uploadImage(data: data, path: path)
                }
            }

            var urls: [String] = []
            for try await url in group {
                urls.append(url)
            }
            return urls
        }
    }
}
