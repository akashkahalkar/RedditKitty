import SwiftUI

struct ZoomableMediaPage: View {
    let item: MediaItem
    let isActive: Bool
    let enhancedUIImage: UIImage?
    let onZoomStateChange: (Bool) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            if let enhancedUIImage {
                zoomableImage(enhancedUIImage, geometry: geometry)
            } else {
                CachedRemoteImage(url: item.mediaURL, thumbnailURL: item.thumbsURL) { image in
                    zoomableImage(image, geometry: geometry).transition(.opacity.combined(with: .scale(scale: 1.02)))
                } placeholder: { thumbnail in
                    if let thumbnail {
                        zoomableImage(thumbnail, geometry: geometry).blur(radius: 1)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } failure: {
                    ContentUnavailableView("Image Unavailable", systemImage: "photo")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .id(item.id)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if !newValue {
                resetTransform()
            }
        }
    }

    private func zoomableImage(_ uiImage: UIImage, geometry: GeometryProxy) -> some View {
        let image = Image(uiImage: uiImage)
        return image
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(magnificationGesture)
            .simultaneousGesture(scale > 1 ? panGesture : nil)
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        toggleZoom()
                    }
            )    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale *= delta
            }
            .onEnded { _ in
                lastScale = 1
                if scale < 1 {
                    withAnimation(.spring()) {
                        resetTransform()
                    }
                } else if scale > 5 {
                    withAnimation(.spring()) {
                        scale = 5
                    }
                }
                onZoomStateChange(scale > 1)
            }
    }

    private var panGesture: some Gesture {
        DragGesture(minimumDistance: scale > 1 ? 0 : 10)
            .onChanged { value in
                guard scale > 1 else { return }

                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard scale > 1 else { return }
                lastOffset = offset
            }
    }

    private func toggleZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            if scale > 1 {
                resetTransform()
            } else {
                scale = 3
                onZoomStateChange(true)
            }
        }
    }

    private func resetTransform() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
        onZoomStateChange(false)
    }
}
