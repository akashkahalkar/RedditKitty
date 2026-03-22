import SwiftUI

struct MediaInfoView: View {
    let item: MediaItem
    let currentIndex: Int
    let totalCount: Int
    let isDownloadingMedia: Bool
    let onDownloadMedia: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.postTitle)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.white)

            HStack(alignment: .center) {
                if let author = item.author, !author.isEmpty {
                    Button {
                        UIPasteboard.general.string = author
                    } label: {
                        Text("u/\(author)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom)
                }

                Spacer()

                
                if let onDownloadMedia {
                    Button {
                        onDownloadMedia()
                    } label: {
                        Image(systemName: isDownloadingMedia ? "arrow.down.circle.fill" : "arrow.down.circle")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .disabled(isDownloadingMedia)
                }

                if !item.isVideo, let url = URL.init(string: item.mediaURL) {
                    Button {
                        Task {
                            let uiImage = try await ImageCacheRepository.shared.image(for: url)
                            await MainActor.run {
                                UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
                            }
                        }
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }.frame(maxWidth: .infinity)
    }
}
