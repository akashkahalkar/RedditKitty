import SwiftUI
import UIKit
internal import Combine

@MainActor
final class CachedImageLoader: ObservableObject {
    enum Phase {
        case idle
        case loading
        case success(Image)
        case failure
    }

    @Published private(set) var phase: Phase = .idle

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    func load(from url: URL?) {
        task?.cancel()
        currentURL = url

        guard let url else {
            phase = .failure
            return
        }

        phase = .loading
        task = Task {
            do {
                let uiImage = try await ImageCacheRepository.shared.image(for: url)
                guard !Task.isCancelled, currentURL == url else { return }
                phase = .success(Image(uiImage: uiImage))
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

struct CachedRemoteImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @StateObject private var loader = CachedImageLoader()

    var body: some View {
        Group {
            switch loader.phase {
            case .idle, .loading:
                placeholder()
            case .success(let image):
                content(image)
            case .failure:
                failure()
            }
        }
        .task(id: url) {
            loader.load(from: url)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
