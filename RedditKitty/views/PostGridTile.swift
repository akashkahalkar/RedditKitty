//
//  PostGridTile.swift
//  RedditKitty
//
//  Created by Akash on 21/03/26.
//

import SwiftUI

struct PostGridTile: View {
    let post: Post
    private let aspectRatio = 0.75

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if post.isVideo {
                if let thumbnailURL = (post.thumbs ?? []).first, !thumbnailURL.isEmpty {
                    CachedRemoteImage(url: URL(string: thumbnailURL)) { uiImage in
                        let image = Image(uiImage: uiImage)
                        image
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(aspectRatio, contentMode: .fill)
                            .clipped()
                            .overlay {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.white)
                            }
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .aspectRatio(aspectRatio, contentMode: .fill)
                            .overlay(alignment: .center) {
                                ProgressView()
                            }
                    } failure: {
                        videoPlaceholder
                    }
                } else {
                    videoPlaceholder
                }
            } else {
                CachedRemoteImage(url: URL(string: (post.thumbs ?? []).first ?? "")) { uiImage in
                    let image = Image(uiImage: uiImage)
                    image
                        .resizable()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(aspectRatio, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(aspectRatio, contentMode: .fill)
                        .overlay(alignment: .center) {
                            ProgressView()
                        }
                } failure: {
                    Rectangle()
                        .fill(.red)
                        .aspectRatio(aspectRatio, contentMode: .fill)
                }
            }

            let imageURLCount = post.imageURLs?.count ?? 0
            if imageURLCount > 1 {
                Text("+\(imageURLCount - 1)")
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.7), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(6)
            }
        }
    }

    private var videoPlaceholder: some View {
        Rectangle()
            .fill(.black.opacity(0.8))
            .aspectRatio(aspectRatio, contentMode: .fill)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(.white)
                    Text("Video")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
    }
}
