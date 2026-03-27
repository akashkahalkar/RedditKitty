//
//  ProfileGridView.swift
//  RedditKitty
//
//  Created by Akash on 21/03/26.
//

import SwiftUI
import SwiftData

enum MediaFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case images = "Images"
    case videos = "Videos"

    var id: String { rawValue }

    var icon: String {
        switch self {
            case .all: "square.grid.2x2"
            case .images: "photo"
            case .videos: "video"
        }
    }
}

struct ProfileGridView: View {
    @Environment(\.modelContext) private var modelContext
    private let sourceKey: String
    private let title: String
    @State private var viewModel = PostsViewModel()
    @State private var selectedViewerPayload: ViewerPayload?
    @State private var selectedFilter: MediaFilter = .all

    private let columns = [
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1),
        GridItem(.flexible(), spacing: 1)
    ]

    init(sourceKey: String, title: String) {
        self.sourceKey = sourceKey
        self.title = title
    }

    private var inferredPostType: PostType {
        if sourceKey.hasPrefix("user:") {
            return .user(title)
        } else {
            return .subreddit(title)
        }
    }

    private var filteredPosts: [Post] {
        switch selectedFilter {
        case .all:
            return viewModel.posts
        case .images:
            return viewModel.posts.filter { !$0.isVideo }
        case .videos:
            return viewModel.posts.filter(\.isVideo)
        }
    }

    var body: some View {
        let tabData = MediaFilter.allCases.map { TabData.init(title: $0.rawValue, icon: $0.icon) }
        
        FloatingTabBar(
            tabData: tabData,
            selectedIndex: Binding(
            get: { MediaFilter.allCases.firstIndex(of: selectedFilter) ?? 0 },
            set: { selectedFilter = MediaFilter.allCases[$0] }
        )) {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
            } else if let errorMessage = viewModel.errorMessage, viewModel.posts.isEmpty {
                ContentUnavailableView("Failed To Load", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                    .padding(.top, 80)
            } else if filteredPosts.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    selectedFilter == .videos ? "No Videos" : (selectedFilter == .images ? "No Images" : "No Media"),
                    systemImage: selectedFilter == .videos ? "video.slash" : "photo.on.rectangle"
                ).padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(filteredPosts) { post in
                        gridTile(for: post)
                            .onAppear {
                                if post.id == filteredPosts.last?.id {
                                    loadMore()
                                }
                            }
                    }
                }

                if viewModel.isLoading && !viewModel.posts.isEmpty {
                    ProgressView().padding()
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.posts.isEmpty {
                await viewModel.fetchPosts(for: inferredPostType, using: modelContext)
            } else {
                viewModel.updateMediaItems()
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedViewerPayload },
            set: { selectedViewerPayload = $0 }
        )) { payload in
            MediaViewerView(items: payload.items, initialIndex: payload.initialIndex, filter: selectedFilter) { postType in
                Task {
                    await viewModel.fetchPosts(for: postType, using: modelContext)
                }
            }
        }
    }

    @ViewBuilder
    private func gridTile(for post: Post) -> some View {
        if !post.isVideo, (post.imageURLs?.count ?? 0) > 1 {
            NavigationLink {
                PostGalleryView(post: post, mediaItems: viewModel.mediaItems, filter: selectedFilter)
            } label: {
                PostGridTile(post: post)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                openViewer(for: post)
            } label: {
                PostGridTile(post: post)
            }
            .buttonStyle(.plain)
        }
    }

    private func openViewer(for post: Post) {
        if let selectedIndex = viewModel.mediaIndexMap[post.id], !viewModel.mediaItems.isEmpty {
            selectedViewerPayload = ViewerPayload(items: viewModel.mediaItems, initialIndex: selectedIndex)
            return
        }

        let fallbackItems = MediaSequenceBuilder.build(from: [post])
        guard !fallbackItems.isEmpty else { return }
        selectedViewerPayload = ViewerPayload(items: fallbackItems, initialIndex: 0)
    }

    private func loadMore() {
        guard viewModel.after != nil else { return }
        Task {
            await viewModel.fetchPosts(for: inferredPostType, using: modelContext, isPagination: true)
        }
    }
}

struct ViewerPayload: Identifiable {
    let id = UUID()
    let items: [MediaItem]
    let initialIndex: Int
}
