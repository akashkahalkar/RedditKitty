import SwiftUI
import UIKit

struct MediaViewerFooterView: View {
    let item: MediaItem

    var body: some View {
        if let author = item.author, !author.isEmpty {
            Button {
                UIPasteboard.general.string = author
            } label: {
                Text("u/\(author)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.bordered)
            .tint(Color.orange).padding(.bottom)
        }
    }
}
