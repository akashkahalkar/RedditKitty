//
//  CachedImageLoader.swift
//  RedditKitty
//
//  Created by Akash on 28/03/26.
//
import SwiftUI

@MainActor
@Observable final class CachedImageLoader {
    enum Phase {
        case idle
        case loading(UIImage?)
        case success(UIImage)
        case failure
    }

    private(set) var phase: Phase = .idle
    private let repository: ImageCacheRepository

    init(repository: ImageCacheRepository = ImageCacheRepository.shared) {
        self.repository = repository
    }

    func load(from url: String, thumbnailURL: String?, debounce: Bool = true) async {

        if debounce {
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            if Task.isCancelled {
                print("---> return due to debound")
                return
            }
        }

        phase = .idle

        guard let url = URL(string: url) else {
            phase = .failure
            return
        }

        let stream = imageStream(for: url, thumbURL: URL(string: thumbnailURL ?? ""))
        for await newPhase in stream {
            self.phase = newPhase
        }
    }

    // 2. The Engine: Produces a stream of UI states
    private func imageStream(for url: URL, thumbURL: URL?) -> AsyncStream<Phase> {
        AsyncStream { continuation in
            let innerTask = Task {
                print("---> started downlaod", url)
                async let mainFetch = repository.image(for: url)

                if let thumbURL {
                    async let thumbFetch = try? repository.image(for: thumbURL)
                    if let thumb = await thumbFetch {
                        continuation.yield(.loading(thumb))
                    }
                } else {
                    continuation.yield(.loading(nil))
                }

                do {
                    let finalImage = try await mainFetch
                    continuation.yield(.success(finalImage))
                    continuation.finish()
                } catch {
                    continuation.yield(.failure)
                    continuation.finish()
                }
            }

            continuation.onTermination = { _ in
                innerTask.cancel()
            }
        }
    }
}
