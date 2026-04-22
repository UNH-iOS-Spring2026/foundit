//
//  CachedAsyncImage.swift
//  foundit
//
//  Image caching solution to prevent unnecessary re-fetching
//  Created by Divya Panthi on 4/11/26.

//

import SwiftUI
import Combine

// MARK: - Image Cache Manager
class ImageCache {
    static let shared = ImageCache()
    
    private init() {
        // Configure cache limits
        cache.countLimit = 100  // Maximum 100 images
        cache.totalCostLimit = 50 * 1024 * 1024  // Maximum 50 MB
    }
    
    private var cache = NSCache<NSString, UIImage>()
    
    func get(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func set(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func clear() {
        cache.removeAllObjects()
    }
}

// MARK: - Cached Async Image Loader
@MainActor
class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let url: URL?
    private var task: Task<Void, Never>?
    
    init(url: URL?) {
        self.url = url
    }
    
    func load() {
        guard let url = url else {
            self.error = NSError(domain: "CachedImageLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            return
        }
        
        // Check cache first
        if let cachedImage = ImageCache.shared.get(forKey: url.absoluteString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // If not cached, download
        guard image == nil && !isLoading else { return }
        
        isLoading = true
        error = nil
        
        task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    ImageCache.shared.set(downloadedImage, forKey: url.absoluteString)
                    self.image = downloadedImage
                    self.error = nil
                }
            } catch {
                self.error = error
                print("[CachedImageLoader] Failed to load image: \(error.localizedDescription)")
            }
            isLoading = false
        }
    }
    
    func cancel() {
        task?.cancel()
    }
    
    deinit {
        task?.cancel()
    }
}

// MARK: - Cached Async Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @StateObject private var loader: CachedImageLoader
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        _loader = StateObject(wrappedValue: CachedImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

// MARK: - Phase-based CachedAsyncImage
struct PhaseCachedAsyncImage<Content: View>: View {
    let url: URL?
    @ViewBuilder let content: (AsyncImagePhase) -> Content
    
    @StateObject private var loader: CachedImageLoader
    
    init(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
        _loader = StateObject(wrappedValue: CachedImageLoader(url: url))
    }
    
    var body: some View {
        Group {
            if let image = loader.image {
                content(.success(Image(uiImage: image)))
            } else if loader.isLoading {
                content(.empty)
            } else if let error = loader.error {
                content(.failure(error))
            } else {
                content(.empty)
            }
        }
        .onAppear {
            loader.load()
        }
    }
}
// MARK: - Convenience initializer with phase-based approach
extension CachedAsyncImage {
    init<V: View>(
        url: URL?,
        @ViewBuilder content: @escaping (AsyncImagePhase) -> V
    ) where Content == AnyView, Placeholder == AnyView {
        self.init(
            url: url,
            content: { image in
                AnyView(content(.success(image)))
            },
            placeholder: {
                AnyView(content(.empty))
            }
        )
    }
}

