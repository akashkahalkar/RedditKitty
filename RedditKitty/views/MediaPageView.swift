import SwiftUI

struct MediaPageView: View {
    let item: MediaItem
    let isActive: Bool
    let shouldPlay: Bool
    let enhancedUIImage: UIImage?
    let onZoomStateChange: (Bool) -> Void

    var body: some View {
        Group {
            if item.isVideo {
                VideoMediaPage(item: item, isActive: isActive, shouldPlay: shouldPlay)
            } else {
                ZoomableMediaPage(
                    item: item,
                    isActive: isActive,
                    enhancedUIImage: enhancedUIImage,
                    onZoomStateChange: onZoomStateChange
                )
            }
        }
        .onAppear {
            if item.isVideo {
                onZoomStateChange(false)
            }
        }
    }
}
