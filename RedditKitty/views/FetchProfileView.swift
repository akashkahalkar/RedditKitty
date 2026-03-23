import SwiftUI

struct FetchProfileView: View {
    @State private var viewModel = PostsViewModel()
    @State private var input = ""
    @State private var isUserMode = true

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                InputSection(viewModel: viewModel, input: $input)
                StatusSection(viewModel: viewModel)
                Spacer()
            }
            .padding()
            .navigationTitle("Fetch Profile")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

#Preview {
    FetchProfileView()
}
