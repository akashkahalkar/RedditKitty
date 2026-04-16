import SwiftUI
import UIKit

struct CachedRemoteImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: String
    let thumbnailURL: String?
    @ViewBuilder let content: (UIImage) -> Content
    @ViewBuilder let placeholder: (UIImage?) -> Placeholder
    @ViewBuilder let failure: () -> Failure

    @State private var loader = CachedImageLoader()

    var body: some View {
        Group {
            switch loader.phase {
                case .idle:
                    placeholder(nil)
                case .loading(let thumbnail):
                    placeholder(thumbnail)
                case .success(let image):
                    content(image)
                case .failure:
                    failure()
            }
        }
        .task(id: url) {
            await loader.load(from: url, thumbnailURL: thumbnailURL)
        }
    }
}
