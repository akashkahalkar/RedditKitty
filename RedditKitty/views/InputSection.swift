import SwiftUI
import UIKit

enum PostTypeInputFilter: String, Identifiable, CaseIterable {

    case user = "u/"
    case subreddit = "r/"

    var id: String { rawValue }
}

struct InputSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: PostsViewModel
    @Binding var input: String
    @State private var hasCheckedPasteboard = false
    @State private var inputFiledPostTypeSelection: PostTypeInputFilter = .user
    @State private var pasteBoardString: String?

    private var postType: PostType {
        inputFiledPostTypeSelection == .user ? .user(input) : .subreddit(input)
    }

    private var placeHolder: String {
        inputFiledPostTypeSelection == .user ? "Reddit username" : "Subreddit name"
    }

    var body: some View {

        VStack(spacing: 12) {
            HStack(spacing: 0) {
                Picker(selection: $inputFiledPostTypeSelection) {
                    ForEach(PostTypeInputFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                } label: {
                    Text(inputFiledPostTypeSelection.rawValue)
                }.pickerStyle(.menu)

                TextField(placeHolder, text: $input)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)


                if !input.isEmpty {
                    Button {
                        input = ""
                    } label: {
                        Image(systemName: "xmark.rectangle.portrait")
                    }.padding(.horizontal)
                }

                if let pasteBoardString, !pasteBoardString.isEmpty {
                    Button {
                        if let postType = parseRedditURL(pasteBoardString) {
                            input = postType.name
                            viewModel.postType = postType
                            withAnimation {
                                switch postType {
                                    case .user:
                                        inputFiledPostTypeSelection = .user
                                    case .subreddit:
                                        inputFiledPostTypeSelection = .subreddit
                                }
                            }
                        } else {
                            input = pasteBoardString
                        }
                    } label: {
                        Image(systemName: "doc.on.doc.fill")
                    }.padding(.trailing)
                }
            }

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
        .onAppear {
            updatePasteboard()
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in
            updatePasteboard()
        }
    }

    private func updatePasteboard() {
        if let pasteBoardString = UIPasteboard.general.string {
            self.pasteBoardString = pasteBoardString
        }
    }

    func parseRedditURL(_ urlString: String) -> PostType? {
        let subRegex = /r\/([a-zA-Z0-9_]+)/
        let userRegex = /u\/([a-zA-Z0-9_-]+)/
        if let subMatch = urlString.firstMatch(of: subRegex) {
            return .subreddit(String(subMatch.1))
        }
        if let userMatch = urlString.firstMatch(of: userRegex) {
            return .user(String(userMatch.1))
        }
        return nil
    }
}
