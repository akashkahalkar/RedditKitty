import Foundation
import UIKit
import CryptoKit

// MARK: - DiskCache Actor

private actor DiskCache {
    func read(from url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func write(_ data: Data, to url: URL) {
        try? data.write(to: url, options: .atomic)
    }
}

// MARK: - ImageCacheRepository Actor

actor ImageCacheRepository {
    static let shared = ImageCacheRepository()

    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 150
        cache.totalCostLimit = 150 * 1024 * 1024
        return cache
    }()

    private let diskCache = DiskCache()
    private let cacheDirectory: URL
    private let fileManager = FileManager.default

    private var activeDownloadsCount = 0
    private let maxConcurrentDownloads = 4
    private var downloadWaiters: [CheckedContinuation<Void, Never>] = []

    private init() {
        let cachesDirectory = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        cacheDirectory = cachesDirectory.appendingPathComponent(
            "RedditKittyImageCache",
            isDirectory: true
        )

        if !FileManager.default.fileExists(atPath: cacheDirectory.path) {
            try? FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
        }
    }

    // MARK: - Public

    func image(for url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString

        // 1. Memory cache — fast path
        if let cached = memoryCache.object(forKey: cacheKey) {
            return cached
        }

        // 2. Disk cache — off actor via DiskCache actor
        let fileURL = cachedFileURL(for: url)
        if let diskImage = await diskCache.read(from: fileURL) {
            memoryCache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // 3. Network download — throttled
        await throttle()
        defer { releaseSlot() }

        try Task.checkCancellation()

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        let cost = Int(image.size.width * image.size.height * 4)
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)
        await diskCache.write(data, to: fileURL)

        return image
    }

    func removeCaches(for urls: [URL]) async {
        let uniqueURLs = Set(urls)
        for url in uniqueURLs {
            removeCache(for: url)
        }
    }

    private func removeCache(for url: URL) {
        let cacheKey = url.absoluteString as NSString
        memoryCache.removeObject(forKey: cacheKey)
        let fileURL = cachedFileURL(for: url)
        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Throttling

    /// Waits until a download slot is available, then atomically claims it.
    private func throttle() async {
        if activeDownloadsCount < maxConcurrentDownloads {
            activeDownloadsCount += 1
            return
        }
        // Slot is claimed by releaseSlot() on this waiter's behalf upon resume
        await withCheckedContinuation { continuation in
            downloadWaiters.append(continuation)
        }
    }

    /// Frees a slot or hands it directly to the next waiter.
    private func releaseSlot() {
        if let next = downloadWaiters.popLast() {
            next.resume()
        } else {
            activeDownloadsCount -= 1
        }
    }

    // MARK: - Helpers

    private func cachedFileURL(for url: URL) -> URL {
        let filename = SHA256.hash(data: Data(url.absoluteString.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return cacheDirectory.appendingPathComponent(filename)
    }
}
