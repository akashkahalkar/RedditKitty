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
    private var streamTask: Task<Void, Never>?

    init(repository: ImageCacheRepository = ImageCacheRepository.shared) {
        self.repository = repository
    }

    func load(from url: URL?, thumbnailURL: URL?) {
        cancel()

        guard let url else {
            phase = .failure
            return
        }

        streamTask = Task {
            let stream = imageStream(for: url, thumbURL: thumbnailURL)
            for await newPhase in stream {
                self.phase = newPhase
            }
        }
    }

    // 2. The Engine: Produces a stream of UI states
    private func imageStream(for url: URL, thumbURL: URL?) -> AsyncStream<Phase> {
        AsyncStream { continuation in
            let innerTask = Task {
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

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        phase = .idle
    }
}
