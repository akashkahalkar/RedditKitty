import SwiftUI
import SwiftData

struct ActionButtons: View {
    @Environment(\.modelContext) private var modelContext
    let viewModel: PostsViewModel
    let input: String
    let isUserMode: Bool

    private var postType: PostType {
        isUserMode ? .user(input) : .subreddit(input)
    }

    var body: some View {
        HStack {
            Button("Fetch") {
                Task { await viewModel.fetchPosts(for: viewModel.postType ?? postType, using: modelContext) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(input.isEmpty)

            Button("Force Refresh") {
                Task { await viewModel.fetchPosts(for: viewModel.postType ?? postType, using: modelContext, forceRefresh: true) }
            }
            .buttonStyle(.bordered)
            .disabled(input.isEmpty)
        }
    }
}
