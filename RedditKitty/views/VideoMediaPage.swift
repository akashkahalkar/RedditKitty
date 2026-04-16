import SwiftUI
import AVKit

struct VideoMediaPage: View {
    let item: MediaItem
    let isActive: Bool
    let shouldPlay: Bool

    @State private var player: AVPlayer?
    @State private var playerItemObserver: NSKeyValueObservation?
    @State private var isPlayerReady = false

    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .opacity(isPlayerReady ? 1 : 0)
                    .onAppear {
                        applyPlaybackState()
                    }
                    .onDisappear {
                        player.pause()
                    }.controlGroupStyle(.menu).controlSize(.mini)

                if !isPlayerReady {
                    placeholderView
                        .transition(.opacity)
                }
            } else {
                placeholderView
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            guard player == nil, let url = URL(string: item.mediaURL) else { return }
            let playerItem = AVPlayerItem(url: url)
            playerItemObserver = playerItem.observe(\.status, options: [.initial, .new]) { item, _ in
                DispatchQueue.main.async {
                    isPlayerReady = item.status == .readyToPlay
                }
            }

            player = AVPlayer(playerItem: playerItem)
            isPlayerReady = playerItem.status == .readyToPlay
            applyPlaybackState()
        }
        .onChange(of: playbackKey) { _, _ in
            applyPlaybackState()
        }
    }

    private var placeholderView: some View {
        Group {
            if let thumbsURL = item.thumbsURL {
                CachedRemoteImage(url: thumbsURL, thumbnailURL: nil) { image in
                    let thumbnail = Image(uiImage: image)
                    thumbnail
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay {
                            Button {
                                //updateIndex(index)
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.white)
                                    .padding()

                            }.buttonStyle(.glass)
                        }
                } placeholder: { _ in
                    ProgressView()
                        .tint(.white)
                } failure: {
                    RoundedRectangle(cornerRadius: 5).fill(.red)
                }
            } else {
                ProgressView()
                    .tint(.white)
            }
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
