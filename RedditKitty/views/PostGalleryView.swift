import SwiftUI

struct PostGalleryView: View {
    let post: Post
    let mediaItems: [MediaItem]
    @State private var selectedMediaIndex: Int?
    let filter: MediaFilter

    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(post.title)
                    .font(.headline)
                    .padding(.horizontal, 8)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array((post.thumbs ?? []).enumerated()), id: \.offset) { index, imageURL in
                        if let selectedIndex = MediaSequenceBuilder.index(for: post, imageIndex: index, in: mediaItems) {
                            Button {
                                selectedMediaIndex = selectedIndex
                            } label: {
                                GalleryThumbnailView(imageURL: imageURL)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Gallery")
        .fullScreenCover(item: Binding(
            get: { 
                if let index = selectedMediaIndex {
                    return SelectionWrapper(index: index)
                }
                return nil
            },
            set: { selectedMediaIndex = $0?.index }
        )) { selection in
            MediaViewerView(items: mediaItems, initialIndex: selection.index, filter: filter, downloadProfileAction: nil)
        }
    }
}

private struct SelectionWrapper: Identifiable {
    let index: Int
    var id: Int { index }
}
