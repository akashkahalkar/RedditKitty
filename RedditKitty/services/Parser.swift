
import Foundation

struct Parser {

    func parse(_ json: [String: Any]) -> (after: String?, posts: [Post]) {
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
                let thumbnails = extractSinglePostThumbnailURL(childData: childData)
                return Post(
                    postId: id,
                    title: title,
                    isGallery: isGallery,
                    isVideo: true,
                    imageURLs: nil,
                    videoURLs: videoURLs,
                    author: author,
                    thumbs: thumbnails
                )
            } else {
                let imageURLs = extractImageURLs(from: childData, isGallery: isGallery)
                let thumbNails = extractThumbnails(from: childData, isGallery: isGallery)
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
                    author: author,
                    thumbs: thumbNails
                )
            }
        }

        return (after, posts)

    }

    private func extractSinglePostURL(childData: [String: Any]) -> [String] {
        let preview = childData["preview"] as? [String: Any]
        let images = preview?["images"] as? [[String: Any]]
        let source = images?.first?["source"] as? [String: Any]
        let rawPreviewURL = source?["url"] as? String

        guard let rawPreviewURL else {
            return []
        }
        return [cleanURL(rawPreviewURL)]
    }

    private func extractSinglePostThumbnailURL(childData: [String: Any]) -> [String] {
        let preview = childData["preview"] as? [String: Any]
        let images = preview?["images"] as? [[String: Any]]
        let thumbs = images?.first?["resolutions"] as? [[String: Any]]
        let thumbURL = thumbs?.first?["url"] as? String

        guard let thumbURL else {
            return []
        }
        return [cleanURL(thumbURL)]
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

    private func extractThumbnails(childData: [String: Any]) -> [String] {
        let mediaMetadata = childData["media_metadata"] as? [String: Any] ?? [:]
        let thumbs = mediaMetadata.values.compactMap { item -> String? in
            guard let metadata = item as? [String: Any],
                  let mediaType = metadata["e"] as? String,
                  mediaType == "Image",
                  let thumbs = metadata["p"] as? [[String: Any]],
                  let thumbUrl = thumbs.first?["u"] as? String else {
                return nil
            }
            return cleanURL(thumbUrl)
        }
        return thumbs
    }

    private func cleanURL(_ rawURL: String) -> String {
        rawURL
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractImageURLs(from childData: [String: Any], isGallery: Bool) -> [String] {
        return isGallery
        ? extractGallaryImages(childData: childData)
        : extractSinglePostURL(childData: childData)
    }

    private func extractThumbnails(from childData: [String: Any], isGallery: Bool) -> [String]  {
        return isGallery
        ? extractThumbnails(childData: childData)
        : extractSinglePostThumbnailURL(childData: childData)
    }
}
