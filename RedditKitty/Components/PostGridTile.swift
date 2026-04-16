//
//  PostGridTile.swift
//  RedditKitty
//
//  Created by Akash on 21/03/26.
//

import SwiftUI
import NukeUI

struct PostGridTile: View {
    let post: Post
    private let aspectRatio = 0.75

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumb = post.thumbs?.first, let url = URL(string: thumb) {
                LazyImage(url: url) { state in
                    if let image = state.image {
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
                    } else {
                        Rectangle()
                            .fill(.gray.opacity(0.2))
                            .aspectRatio(aspectRatio, contentMode: .fill)
                            .overlay(alignment: .center) {
                                ProgressView()
                            }
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
