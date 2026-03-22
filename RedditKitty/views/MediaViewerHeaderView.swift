import SwiftUI

struct MediaViewerHeaderView: View {
    let item: MediaItem
    let currentIndex: Int
    let totalCount: Int
    let isDownloadingMedia: Bool
    let onDownloadMedia: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.postTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.white)
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

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
