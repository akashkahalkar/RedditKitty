import SwiftUI

struct StatusSection: View {
    let viewModel: PostsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isLoading {
                ProgressView().padding(.vertical)
            }
            if let activeSourceName = viewModel.sourceName,
               let activeSourceType = viewModel.postType {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(activeSourceType.displayLabel): \(activeSourceName)").font(.headline)
                    Text("Posts: \(viewModel.postCount)")
                    Text("After: \(viewModel.after ?? "-")")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.top)
            }
        }
    }
}
