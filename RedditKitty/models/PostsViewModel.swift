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

    private let parser = Parser()

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
            let parsed = parser.parse(response)

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
}
