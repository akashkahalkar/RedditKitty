import SwiftUI

struct GalleryThumbnailView: View {
    let imageURL: String
    let thumbnailURL: String?
    private let aspectRatio = 0.75

    var body: some View {
        CachedRemoteImage(url: URL(string: imageURL), thumbnailURL: URL(string: thumbnailURL ?? "")) { image in
            let image = Image(uiImage: image)
            image
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fill)
                .clipped()
                .transition(.opacity)
        } placeholder: { thumbnail in
            if let thumbnail {
                let thumbnailImage = Image(uiImage: thumbnail)
                thumbnailImage
                    .resizable()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(aspectRatio, contentMode: .fill)
                    .clipped()
                    .blur(radius: 1)
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .aspectRatio(aspectRatio, contentMode: .fill)
                    .overlay {
                        ProgressView()
                    }
            }

        } failure: {
            Rectangle()
                .fill(.red.opacity(0.15))
                .aspectRatio(aspectRatio, contentMode: .fill)
        }
    }
}
