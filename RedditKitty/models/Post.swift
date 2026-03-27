import Foundation

enum PostType: Hashable, Sendable {
    case user(String)
    case subreddit(String)

    var name: String {
        switch self {
        case .user(let name), .subreddit(let name):
            return name
        }
    }

    var cacheKey: String {
        switch self {
        case .user(let name):
            return "user:\(name)"
        case .subreddit(let name):
            return "subreddit:\(name)"
        }
    }

    var displayLabel: String {
        switch self {
        case .user:
            return "User"
        case .subreddit:
            return "Subreddit"
        }
    }
}

struct Post: Identifiable, Sendable, Equatable {
    let postId: String
    let title: String
    let isGallery: Bool
    let isVideo: Bool
    let imageURLs: [String]?
    let videoURLs: [String]?
    let author: String?
    var id: String { postId }
    let thumbs: [String]?
}
