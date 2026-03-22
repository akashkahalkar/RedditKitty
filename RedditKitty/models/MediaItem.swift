import Foundation

enum MediaKind: String, Hashable, Sendable {
    case image
    case video
}

struct MediaItem: Identifiable, Hashable, Sendable {

    let postId: String
    let postTitle: String
    let author: String?
    let mediaURL: String
    let kind: MediaKind
    let videoDownloadURL: String?
    let imageIndexInPost: Int

    var isVideo: Bool {
        kind == .video
    }

    var id: String {
        "\(postId)|\(imageIndexInPost)|\(mediaURL)|\(kind.rawValue)"
    }
}
