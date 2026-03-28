import SwiftUI

struct TilePlaceholder: View {
        let icon: String = "play.circle.fill"
        let showTitle: Bool = false

        var body: some View {
            Rectangle()
                .fill(.black.opacity(0.8))
                .aspectRatio(1, contentMode: .fill)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 34))
                            .foregroundStyle(.white)
                        if showTitle {
                            Text("Video")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

        }
    }
