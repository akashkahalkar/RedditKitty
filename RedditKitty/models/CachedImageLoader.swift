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
    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(from url: URL?, thumbnailURL: URL?) {
        task?.cancel()
        currentURL = url

        guard let url else {
            phase = .failure
            return
        }

        Task {
            if let thumbnailURL {
                let thumbImage = try await ImageCacheRepository.shared.image(for: thumbnailURL)
                guard !Task.isCancelled, currentURL == url else { return }
                if case .success = phase { return }
                phase = .loading(thumbImage)
            } else if case .idle = phase {
                phase = .loading(nil)
            }
        }
        task = Task {
            do {
                let uiImage = try await ImageCacheRepository.shared.image(for: url)
                guard !Task.isCancelled, currentURL == url else { return }
                phase = .success(uiImage)
            } catch {
                guard !Task.isCancelled, currentURL == url else { return }
                phase = .failure
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
