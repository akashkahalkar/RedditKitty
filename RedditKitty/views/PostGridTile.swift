//
//  PostGridTile.swift
//  RedditKitty
//
//  Created by Akash on 21/03/26.
//

import SwiftUI

struct PostGridTile: View {
    let post: Post

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if post.isVideo {
                if let thumbnailURL = (post.imageURLs ?? []).first, !thumbnailURL.isEmpty {
                    CachedRemoteImage(url: URL(string: thumbnailURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .overlay {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.white)
                            }
                    } placeholder: {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
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
                CachedRemoteImage(url: URL(string: (post.imageURLs ?? []).first ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fill)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(alignment: .center) {
                            ProgressView()
                        }
                } failure: {
                    Rectangle()
                        .fill(.red)
                        .aspectRatio(1, contentMode: .fit)
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
            .aspectRatio(1, contentMode: .fit)
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
