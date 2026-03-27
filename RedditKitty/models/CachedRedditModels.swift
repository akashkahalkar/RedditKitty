import Foundation
import SwiftData

@Model
final class CachedListing {
    @Attribute(.unique) var sourceKey: String
    var sourceName: String
    var sourceKind: String
    var afterCursor: String?
    var fetchedAt: Date

    init(postType: PostType, afterCursor: String?, fetchedAt: Date = .now) {
        self.sourceKey = postType.cacheKey
        self.sourceName = postType.name
        self.sourceKind = {
            switch postType {
            case .user:
                return "user"
            case .subreddit:
                return "subreddit"
            }
        }()
        self.afterCursor = afterCursor
        self.fetchedAt = fetchedAt
    }
}

@Model
final class CachedPost {
    @Attribute(.unique) var cacheKey: String
    var sourceKey: String
    var postID: String
    var title: String
    var isGallery: Bool
    var orderIndex: Int
    var imageURLsBlob: Data
    var videoURLsBlob: Data
    var isVideo: Bool
    var author: String
    var thumbURLsBlob: Data

    init(postType: PostType, post: Post, orderIndex: Int) {
        self.cacheKey = "\(postType.cacheKey)|\(post.postId)"
        self.sourceKey = postType.cacheKey
        self.postID = post.postId
        self.title = post.title
        self.isGallery = post.isGallery
        self.orderIndex = orderIndex
        self.author = post.author ?? ""
        self.imageURLsBlob = (try? JSONEncoder().encode(post.imageURLs)) ?? Data()
        self.videoURLsBlob = (try? JSONEncoder().encode(post.videoURLs)) ?? Data()
        self.thumbURLsBlob = (try? JSONEncoder().encode(post.thumbs)) ?? Data()
        self.isVideo = post.isVideo
    }

    var imageURLs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: imageURLsBlob)) ?? []
        }
        set {
            imageURLsBlob = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var videoURLs: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: videoURLsBlob)) ?? []
        }
        set {
            videoURLsBlob = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var thumbUrls: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: thumbURLsBlob)) ?? []
        }
        set {
            thumbURLsBlob = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    var post: Post {
        Post(
            postId: postID,
            title: title,
            isGallery: isGallery,
            isVideo: isVideo,
            imageURLs: imageURLs,
            videoURLs: videoURLs,
            author: author,
            thumbs: thumbUrls
        )
    }
}
