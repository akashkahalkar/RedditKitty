import SwiftUI

struct GalleryThumbnailView: View {
    let imageURL: String
    private let aspectRatio = 0.75

    var body: some View {
        CachedRemoteImage(url: URL(string: imageURL)) { image in
            let image = Image(uiImage: image)
            image
                .resizable()
                .frame(maxWidth: .infinity)
                .aspectRatio(aspectRatio, contentMode: .fill)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .aspectRatio(aspectRatio, contentMode: .fill)
                .overlay {
                    ProgressView()
                }
        } failure: {
            Rectangle()
                .fill(.red.opacity(0.15))
                .aspectRatio(aspectRatio, contentMode: .fill)
        }
    }
}
