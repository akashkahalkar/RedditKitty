import SwiftUI

struct MediaInfoView: View {
    let item: MediaItem
    let currentIndex: Int
    let totalCount: Int
    let isDownloadingMedia: Bool
    let onDownloadMedia: (() -> Void)?
    let isEnhancingCurrentItem: Bool
    let isCurrentItemEnhanced: Bool
    let onToggleEnhancement: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            Text(item.postTitle)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.white)

            HStack(alignment: .center) {
                if let author = item.author, !author.isEmpty, let authorNameWithPrefix = item.authorNameWithPrefix {
                    Button {
                        UIPasteboard.general.string = authorNameWithPrefix
                    } label: {
                        Text(authorNameWithPrefix)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.bordered)
                    .padding(.bottom)
                }

                Spacer()

                if !item.isVideo {
                    Button {
                        onToggleEnhancement?()
                    } label: {
                        if isEnhancingCurrentItem {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: isCurrentItemEnhanced ? "sparkles" : "sparkle")
                        }
                    }
                    .font(.title2)
                    .disabled(isEnhancingCurrentItem || onToggleEnhancement == nil)
                }


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
