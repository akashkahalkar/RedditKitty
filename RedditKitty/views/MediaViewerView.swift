import SwiftUI

struct MediaViewerView: View {
    @Environment(\.dismiss) private var dismiss

    let items: [MediaItem]
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var isCurrentItemZoomed = false
    @State private var isUIVisible = true
    @State private var isDraggingDismiss = false
    @State private var shouldPlayActiveVideo = true
    @State private var isDownloadingMedia = false
    @State private var mediaDownloadError: String?
    @State private var shareURL: ShareURLWrapper?
    @AppStorage(AppSettings.autoPlayVideoKey) private var autoPlayVideo = true

    init(items: [MediaItem], initialIndex: Int) {
        self.items = items
        _currentIndex = State(initialValue: initialIndex)
        _shouldPlayActiveVideo = State(initialValue: autoPlayVideo)
    }

    var body: some View {
        baseContent
        .simultaneousGesture(
            dismissGesture,
            including: isCurrentItemZoomed ? .subviews : .all
        )
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .sheet(item: $shareURL) { file in
            ActivityView(activityItems: [file.url])
        }
        .alert("Download Failed", isPresented: isDownloadErrorPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(mediaDownloadError ?? "Unable to download media.")
        }
    }

    private var baseContent: some View {
        ZStack {
            backgroundView
            viewerStack
        }
    }

    private var backgroundView: some View {
        Color.black
            .ignoresSafeArea()
            .opacity(1.0)
    }

    private var viewerStack: some View {
        ZStack {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            mediaPager
            if isUIVisible {
                VStack {
                    Spacer()
                    infoSection
                }
            }
        }
        .offset(y: dragOffset.height)
        .scaleEffect(1.0 - (abs(dragOffset.height) / 1800.0))
    }

    @ViewBuilder
    private var infoSection: some View {
        MediaInfoView(
            item: currentItem,
            currentIndex: currentIndex,
            totalCount: items.count,
            isDownloadingMedia: isDownloadingMedia,
            onDownloadMedia: onDownloadMediaAction
        )
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(Color.black.opacity(0.4))
        .zIndex(1)
    }

    private var mediaPager: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(0..<items.count, id: \.self) { index in
                    let item = items[index]
                    MediaPageView(
                        item: item,
                        isActive: index == currentIndex,
                        shouldPlay: shouldPlayActiveVideo
                    ) { isZoomed in
                        if index == currentIndex {
                            isCurrentItemZoomed = isZoomed
                        }
                    }
                    .id(index)
                    .containerRelativeFrame(.horizontal)
                    .onTapGesture {
                        withAnimation(.easeIn) {
                            isUIVisible.toggle()
                        }
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: Binding(
            get: { currentIndex },
            set: { if let val = $0 { currentIndex = val } }
        ))
        .disabled(isDraggingDismiss)
        .simultaneousGesture(mediaDragGesture)
        .onChange(of: currentIndex) { _, _ in
            setShouldPlayActiveVideo(autoPlayVideo)
        }
    }

    private var onDownloadMediaAction: (() -> Void)? {
        guard resolvedDownloadURL != nil else {
            return nil
        }
        return { downloadCurrentMedia() }
    }

    private var isDownloadErrorPresented: Binding<Bool> {
        Binding(
            get: { mediaDownloadError != nil },
            set: { if !$0 { mediaDownloadError = nil } }
        )
    }

    private var resolvedDownloadURL: URL? {
        let rawURL = currentItem.isVideo ? currentItem.videoDownloadURL : currentItem.mediaURL
        guard let rawURL, !rawURL.isEmpty else { return nil }
        return URL(string: rawURL)
    }

    private var currentItem: MediaItem {
        items[currentIndex]
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                if !isDraggingDismiss && abs(value.translation.height) > abs(value.translation.width) {
                    isDraggingDismiss = true
                    setShouldPlayActiveVideo(false)
                }

                if isDraggingDismiss {
                    dragOffset.height = value.translation.height
                    if isUIVisible && value.translation.height > 20 {
                        withAnimation(.easeInOut) {
                            isUIVisible = true
                        }
                    }
                }
            }
            .onEnded { value in
                if isDraggingDismiss {
                    let velocity = value.predictedEndTranslation.height - value.translation.height

                    if value.translation.height > 150 || (value.translation.height > 50 && velocity > 250) {
                        withAnimation(.interactiveSpring(response: 0.26, dampingFraction: 0.9, blendDuration: 0.1)) {
                            dragOffset.height = 900
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            dismiss()
                        }
                    } else {
                        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.88)) {
                            dragOffset = .zero
                        }
                    }
                }
                isDraggingDismiss = false
                if value.translation.height <= 150 {
                    setShouldPlayActiveVideo(false)
                }
            }
    }

    private var mediaDragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { _ in
                if currentItem.isVideo {
                    setShouldPlayActiveVideo(false)
                }
            }
            .onEnded { _ in
                setShouldPlayActiveVideo(autoPlayVideo)
            }
    }

    private func setShouldPlayActiveVideo(_ shouldPlay: Bool) {
        guard shouldPlayActiveVideo != shouldPlay else { return }
        shouldPlayActiveVideo = shouldPlay
    }

    private func downloadCurrentMedia() {
        guard !isDownloadingMedia, let url = resolvedDownloadURL else {
            return
        }

        isDownloadingMedia = true
        mediaDownloadError = nil

        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: url)

                let fileManager = FileManager.default
                let targetFileName = sanitizedFileName(from: currentItem.postTitle) + "." + downloadFileExtension(for: url)
                let destinationURL = fileManager.temporaryDirectory.appendingPathComponent(targetFileName)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: tempURL, to: destinationURL)

                await MainActor.run {
                    shareURL = ShareURLWrapper(url: destinationURL)
                }
            } catch {
                await MainActor.run {
                    mediaDownloadError = error.localizedDescription
                }
            }

            await MainActor.run {
                isDownloadingMedia = false
            }
        }
    }

    private func downloadFileExtension(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        if !ext.isEmpty {
            return ext
        }
        return currentItem.isVideo ? "mp4" : "jpg"
    }

    private func sanitizedFileName(from rawTitle: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = rawTitle.components(separatedBy: invalid).joined(separator: "_")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "video" : cleaned
    }
}

private struct ShareURLWrapper: Identifiable {
    let id = UUID()
    let url: URL
}
