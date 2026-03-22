import SwiftUI
import AVKit

struct VideoMediaPage: View {
    let item: MediaItem
    let isActive: Bool
    let shouldPlay: Bool

    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .onAppear {
                        applyPlaybackState()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            guard player == nil, let url = URL(string: item.mediaURL) else { return }
            player = AVPlayer(url: url)
            applyPlaybackState()
        }
        .onChange(of: playbackKey) { _, _ in
            applyPlaybackState()
        }
    }

    private var playbackKey: String {
        "\(isActive)-\(shouldPlay)"
    }

    private func applyPlaybackState() {
        guard let player else { return }
        if isActive && shouldPlay {
            player.play()
        } else {
            player.pause()
        }
    }
}
