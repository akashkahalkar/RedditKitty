import Foundation

enum MediaSequenceBuilder {
    static func build(from posts: [Post]) -> [MediaItem] {
        posts.reduce(into: [MediaItem]()) { items, post in
            if post.isVideo, let videoURLs = post.videoURLs, !videoURLs.isEmpty {
                guard let resolved = resolvedVideoURLs(from: videoURLs) else {
                    return
                }

                items.append(
                    MediaItem(
                        postId: post.postId,
                        postTitle: post.title,
                        author: post.author,
                        mediaURL: resolved.playbackURL,
                        thumbsURL: post.thumbs?.first,
                        kind: .video,
                        videoDownloadURL: resolved.downloadURL,
                        imageIndexInPost: 0
                    )
                )
                return
            }

            let imageItems = (post.imageURLs ?? []).enumerated().map { index, imageURL in
                let thumbURL = (post.thumbs?.indices.contains(index) == true) ? post.thumbs?[index] : nil
                return MediaItem(
                    postId: post.postId,
                    postTitle: post.title,
                    author: post.author,
                    mediaURL: imageURL,
                    thumbsURL: thumbURL,
                    kind: .image,
                    videoDownloadURL: nil,
                    imageIndexInPost: index
                )
            }
            items.append(contentsOf: imageItems)
        }
    }

    static func firstIndex(for post: Post, in items: [MediaItem]) -> Int? {
        items.firstIndex {
            $0.postId == post.postId && $0.imageIndexInPost == 0
        }
    }

    static func index(for post: Post, imageIndex: Int, in items: [MediaItem]) -> Int? {
        items.firstIndex {
            $0.postId == post.postId && $0.imageIndexInPost == imageIndex
        }
    }

    private static func resolvedVideoURLs(from urls: [String]) -> (playbackURL: String, downloadURL: String?)? {
        let cleaned = urls.map(cleanURL).filter { !$0.isEmpty }
        guard !cleaned.isEmpty else { return nil }

        let m3u8 = cleaned.first(where: isM3U8URL)
        let mp4 = cleaned.first(where: isMP4URL)

        return (
            playbackURL: m3u8 ?? mp4 ?? cleaned[0],
            downloadURL: mp4
        )
    }

    nonisolated
    private static func cleanURL(_ rawURL: String) -> String {
        rawURL
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated
    private static func isM3U8URL(_ rawURL: String) -> Bool {
        URL(string: rawURL)?
            .pathExtension
            .lowercased() == "m3u8"
    }

    nonisolated
    private static func isMP4URL(_ rawURL: String) -> Bool {
        URL(string: rawURL)?
            .pathExtension
            .lowercased() == "mp4"
    }
}
