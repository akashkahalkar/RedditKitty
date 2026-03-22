import SwiftUI

struct GalleryThumbnailView: View {
    let imageURL: String

    var body: some View {
        CachedRemoteImage(url: URL(string: imageURL)) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    ProgressView()
                }
        } failure: {
            Rectangle()
                .fill(.red.opacity(0.15))
                .aspectRatio(1, contentMode: .fit)
        }
    }
}
