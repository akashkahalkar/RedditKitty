import Foundation
import SwiftData

@MainActor
@Observable final class PostsViewModel {
    private(set) var posts: [Post] = []
    private(set) var mediaItems: [MediaItem] = []
    private(set) var mediaIndexMap: [String: Int] = [:]
    private(set) var isLoading = false
    private(set) var after: String?
    private(set) var sourceName: String?
    var errorMessage: String?
    var postType: PostType?

    @MainActor
    @ObservationIgnored private var isProcessing = false
    @ObservationIgnored private var mediaBuilderTask: Task<Void, Never>?

    var postCount: Int { posts.count }

    func fetchPosts(for postType: PostType, using modelContext: ModelContext, forceRefresh: Bool = false, isPagination: Bool = false) async {
        let normalizedPostType = normalize(postType)
        guard !normalizedPostType.name.isEmpty else {
            errorMessage = "Enter a valid name."
            return
        }

        if isProcessing { return }
        isProcessing = true
        
        isLoading = true
        errorMessage = nil
        self.postType = normalizedPostType
        self.sourceName = normalizedPostType.name

        // If not force refresh and not paginating, try to load from cache first
        if !forceRefresh && !isPagination {
            let loaded = await loadCachedPosts(for: normalizedPostType, using: modelContext)
            if loaded {
                isLoading = false
                isProcessing = false
                return
            }
        }

        do {
            let baseURL = baseURL(for: normalizedPostType).replacingOccurrences(of: "{name}", with: normalizedPostType.name)
            let currentAfter = isPagination ? after : nil
            let userPostURL = getUserPostURL(urlString: baseURL, limit: AppSettings.pageLimit, after: currentAfter)
            
            let response = try await NetworkManager.shared.getJSON(userPostURL)
            let parsed = parse(response)
            
            self.after = parsed.after
            
            if isPagination {
                self.posts.append(contentsOf: parsed.posts)
            } else {
                self.posts = parsed.posts
            }
            
            updateMediaItems()
            try await saveCachedPosts(for: normalizedPostType, using: modelContext, after: parsed.after, posts: parsed.posts, isAppend: isPagination)
        } catch {
            var loadedCache = false
            if !isPagination {
                loadedCache = await loadCachedPosts(for: normalizedPostType, using: modelContext)
            }

            if loadedCache {
                errorMessage = "Showing cached data. \(error.localizedDescription)"
            } else {
                if !isPagination {
                    posts = []
                    after = nil
                    mediaItems = []
                    mediaIndexMap = [:]
                }
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
        isProcessing = false
    }

    func updateMediaItems() {
        mediaBuilderTask?.cancel()
        let currentPosts = self.posts
        
        mediaBuilderTask = Task.detached(priority: .userInitiated) {
            let items = await MediaSequenceBuilder.build(from: currentPosts)
            
            var indexMap: [String: Int] = [:]
            for (index, item) in items.enumerated() {
                if indexMap[item.postId] == nil {
                    indexMap[item.postId] = index
                }
            }
            
            if Task.isCancelled { return }
            
            let finalizedItems = items
            let finalizedIndexMap = indexMap
            
            await MainActor.run {
                self.mediaItems = finalizedItems
                self.mediaIndexMap = finalizedIndexMap
            }
        }
    }

    private func baseURL(for type: PostType) -> String {
        switch type {
            case .user:
                return "https://www.reddit.com/user/{name}/.json"
            case .subreddit:
                return "https://www.reddit.com/r/{name}/.json"
        }
    }

    private func getUserPostURL(urlString: String, limit: Int?, after: String?) -> String {
        guard var urlComponents = URLComponents(string: urlString) else {
            return urlString
        }

        var queryItems = urlComponents.queryItems ?? []

        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }

        if let after {
            queryItems.append(URLQueryItem(name: "after", value: after))
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url?.absoluteString ?? urlString
    }

    private func parse(_ json: [String: Any]) -> (after: String?, posts: [Post]) {
        guard let data = json["data"] as? [String: Any] else {
            return (nil, [])
        }

        let after = data["after"] as? String
        let children = data["children"] as? [[String: Any]] ?? []
        var seenIDs = Set<String>()

        let posts = children.compactMap { child -> Post? in
            guard let childData = child["data"] as? [String: Any],
                  let id = childData["name"] as? String,
                  let rawTitle = childData["title"] as? String else {
                return nil
            }

            let author = childData["author"] as? String
            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let isGallery = childData["is_gallery"] as? Bool ?? false
            let postHint = childData["post_hint"] as? String

            if postHint == "rich:video" || postHint == "hosted:video" {
                let videoURLs = extractVideoURL(childData: childData)
                let thumbnails = extractVideoThumbnailURL(childData: childData)
                return Post(
                    postId: id,
                    title: title,
                    isGallery: isGallery,
                    isVideo: true,
                    imageURLs: thumbnails,
                    videoURLs: videoURLs,
                    author: author
                )
            } else {
                let imageURLs = extractImageURLs(from: childData, isGallery: isGallery)
                guard !title.isEmpty, !imageURLs.isEmpty, seenIDs.insert(id).inserted else {
                    return nil
                }
                return Post(
                    postId: id,
                    title: title,
                    isGallery: isGallery,
                    isVideo: false,
                    imageURLs: imageURLs,
                    videoURLs: nil,
                    author: author
                )
            }
        }

        return (after, posts)
    }

    func loadCachedPosts(for postType: PostType, using modelContext: ModelContext) async -> Bool {
        let container = modelContext.container
        let sourceKey = postType.cacheKey

        do {
            typealias CachedResult = (afterCursor: String?, sourceName: String, sourceKind: String, posts: [Post])
            
            let result: CachedResult? = try await Task.detached(priority: .userInitiated) {
                let backgroundContext = ModelContext(container)
                
                let listingDescriptor = FetchDescriptor<CachedListing>(
                    predicate: #Predicate { $0.sourceKey == sourceKey }
                )

                guard let listing = try backgroundContext.fetch(listingDescriptor).first else {
                    return nil
                }

                let postsDescriptor = FetchDescriptor<CachedPost>(
                    predicate: #Predicate { $0.sourceKey == sourceKey },
                    sortBy: [SortDescriptor(\.orderIndex)]
                )

                let cachedPosts = try backgroundContext.fetch(postsDescriptor)
                let allPosts = cachedPosts.map(\.post)
                
                return (listing.afterCursor, listing.sourceName, listing.sourceKind, allPosts)
            }.value

            if let result {
                self.after = result.afterCursor
                self.sourceName = result.sourceName
                self.postType = result.sourceKind == "user" ? .user(result.sourceName) : .subreddit(result.sourceName)
                self.posts = result.posts
                updateMediaItems()
                return true
            }
            return false
        } catch {
            return false
        }
    }

    private func saveCachedPosts(for postType: PostType, using modelContext: ModelContext, after: String?, posts: [Post], isAppend: Bool = false) async throws {
        let container = modelContext.container
        
        try await Task.detached(priority: .userInitiated) {
            let backgroundContext = ModelContext(container)
            let sourceKey = await postType.cacheKey

            let listingDescriptor = FetchDescriptor<CachedListing>(
                predicate: #Predicate { $0.sourceKey == sourceKey }
            )

            let listing = try backgroundContext.fetch(listingDescriptor).first ?? {
                let newListing = CachedListing(postType: postType, afterCursor: after)
                backgroundContext.insert(newListing)
                return newListing
            }()

            listing.sourceName = await postType.name
            listing.afterCursor = after
            listing.fetchedAt = .now

            var startIndex = 0
            
            if !isAppend {
                let oldPostsDescriptor = FetchDescriptor<CachedPost>(
                    predicate: #Predicate { $0.sourceKey == sourceKey }
                )
                let oldPosts = try backgroundContext.fetch(oldPostsDescriptor)
                for oldPost in oldPosts {
                    backgroundContext.delete(oldPost)
                }
            } else {
                // Find the current max index to append correctly
                let oldPostsDescriptor = FetchDescriptor<CachedPost>(
                    predicate: #Predicate { $0.sourceKey == sourceKey },
                    sortBy: [SortDescriptor(\.orderIndex, order: .reverse)]
                )
                var fetchLimitDescriptor = oldPostsDescriptor
                fetchLimitDescriptor.fetchLimit = 1
                
                if let lastPost = try backgroundContext.fetch(fetchLimitDescriptor).first {
                    startIndex = lastPost.orderIndex + 1
                }
            }
            
            try backgroundContext.save()

            for (index, post) in posts.enumerated() {
                backgroundContext.insert(CachedPost(postType: postType, post: post, orderIndex: startIndex + index))
            }

            try backgroundContext.save()
        }.value
    }

    private func normalize(_ postType: PostType) -> PostType {
        let trimmed = postType.name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch postType {
        case .user:
            if trimmed.hasPrefix("/u/") {
                return .user(String(trimmed.dropFirst(3)))
            }

            if trimmed.hasPrefix("u/") {
                return .user(String(trimmed.dropFirst(2)))
            }

            return .user(trimmed)
        case .subreddit:
            if trimmed.hasPrefix("/r/") {
                return .subreddit(String(trimmed.dropFirst(3)))
            }

            if trimmed.hasPrefix("r/") {
                return .subreddit(String(trimmed.dropFirst(2)))
            }

            return .subreddit(trimmed)
        }
    }

    private func extractImageURLs(from childData: [String: Any], isGallery: Bool) -> [String] {
        return isGallery
        ? extractGallaryImages(childData: childData)
        : extractSinglePostURL(childData: childData)
    }

    private func cleanURL(_ rawURL: String) -> String {
        rawURL
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractSinglePostURL(childData: [String: Any]) -> [String] {
        let preview = childData["preview"] as? [String: Any]
        let images = preview?["images"] as? [[String: Any]]
        let source = images?.first?["source"] as? [String: Any]
        let rawPreviewURL = source?["url"] as? String

        if let rawPreviewURL {
            let cleanedURL = cleanURL(rawPreviewURL)
            return cleanedURL.isEmpty ? [] : [cleanedURL]
        }
        return []
    }

    private func extractVideoThumbnailURL(childData: [String: Any]) -> [String] {
        let preview = childData["preview"] as? [String: Any]
        let images = preview?["images"] as? [[String: Any]]
        let resolutions = images?.first?["resolutions"] as? [[String: Any]]
        let rawPreviewURL = resolutions?.first?["url"] as? String

        if let rawPreviewURL {
            let cleanedURL = cleanURL(rawPreviewURL)
            return cleanedURL.isEmpty ? [] : [cleanedURL]
        }
        return []
    }

    private func extractVideoURL(childData: [String: Any]) -> [String] {
        let isVideo = childData["is_video"] as? Bool ?? false
        if isVideo {
            let media = childData["media"] as? [String: Any]
            let redditVideo = media?["reddit_video"] as? [String: Any]
            let fallbackURL = redditVideo?["fallback_url"] as? String
            let hls = redditVideo?["hls_url"] as? String

            return [hls, fallbackURL].compactMap { $0 }
        } else {
            let preview = childData["preview"] as? [String: Any]
            let videoPreview = preview?["reddit_video_preview"] as? [String: Any]
            let hls = videoPreview?["hls_url"] as? String
            let fallbackURL = videoPreview?["fallback_url"] as? String

            return [hls, fallbackURL].compactMap { $0 }
        }
    }

    private func extractGallaryImages(childData: [String: Any]) -> [String] {
        let mediaMetadata = childData["media_metadata"] as? [String: Any] ?? [:]

        return mediaMetadata.values.compactMap { item -> String? in
            guard let metadata = item as? [String: Any],
                  let mediaType = metadata["e"] as? String,
                  mediaType == "Image",
                  let source = metadata["s"] as? [String: Any],
                  let rawURL = source["u"] as? String else {
                return nil
            }
            return cleanURL(rawURL)
        }
    }
}
