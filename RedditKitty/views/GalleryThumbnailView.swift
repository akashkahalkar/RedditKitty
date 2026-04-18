import SwiftUI
import NukeUI

struct GalleryThumbnailView: View {
    let imageURL: String
    let thumbnailURL: String?
    private let aspectRatio = 0.75

    var body: some View {
        if let url = URL.init(string: imageURL) {
            LazyImage(url: url)
                .frame(maxWidth: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fill)
        } else {
            Rectangle()
                .fill(.red.opacity(0.15))
                .aspectRatio(aspectRatio, contentMode: .fill)
        }
    }
}
