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
            if let thumb = post.thumbs?.first {
                CachedRemoteImage(url: URL(string: thumb), thumbnailURL: nil) { uiImage in
                    let image = Image(uiImage: uiImage)
                    image
                        .resizable()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(aspectRatio, contentMode: .fill)
                        .clipped()
                        .overlay {
                            if post.isVideo {
                                TilePlaceholder()
                            }
                        }
                } placeholder: { _ in
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(aspectRatio, contentMode: .fill)
                        .overlay(alignment: .center) {
                            ProgressView()
                        }
                } failure: {
                    if post.isVideo {
                        TilePlaceholder()
                    }
                }
            } else {
                if post.isVideo {
                    TilePlaceholder()
                } else {
                    ProgressView()
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
}
