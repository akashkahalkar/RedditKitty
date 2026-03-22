import SwiftUI

struct FetchProfileView: View {
    @State private var viewModel = PostsViewModel()
    @State private var input = ""
    @State private var isUserMode = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                InputSection(input: $input, isUserMode: $isUserMode, postType: $viewModel.postType)
                ActionButtons(viewModel: viewModel, input: input, isUserMode: isUserMode)
                StatusSection(viewModel: viewModel)
                Spacer()
            }
            .padding()
            .navigationTitle("Fetch Profile")
        }
    }
}

#Preview {
    FetchProfileView()
}
