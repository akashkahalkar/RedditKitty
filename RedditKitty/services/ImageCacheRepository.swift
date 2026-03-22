import Foundation
import UIKit
import CryptoKit

actor ImageCacheRepository {
    static let shared = ImageCacheRepository()

    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        cache.totalCostLimit = 150 * 1024 * 1024 // ~150MB roughly
        return cache
    }()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private var activeDownloadsCount = 0
    private let maxConcurrentDownloads = 6
    private var downloadWaiters: [CheckedContinuation<Void, Never>] = []

    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        cacheDirectory = cachesDirectory.appendingPathComponent("RedditKittyImageCache", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    func image(for url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString

        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            return cachedImage
        }

        let fileURL = cachedFileURL(for: url)
        if let diskImage = imageFromDisk(at: fileURL) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // Concurrency limiting for network downloads
        if activeDownloadsCount >= maxConcurrentDownloads {
            await withCheckedContinuation { continuation in
                downloadWaiters.append(continuation)
            }
        }
        
        activeDownloadsCount += 1
        
        defer {
            activeDownloadsCount -= 1
            if !downloadWaiters.isEmpty {
                let next = downloadWaiters.removeFirst()
                next.resume()
            }
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)
        try? data.write(to: fileURL, options: .atomic)
        return image
    }

    private func imageFromDisk(at url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    private func cachedFileURL(for url: URL) -> URL {
        let filename = SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()

        return cacheDirectory.appendingPathComponent(filename)
    }
}
