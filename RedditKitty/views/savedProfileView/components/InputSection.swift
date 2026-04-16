import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftData

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
                    .textFieldStyle(.plain)


                if !input.isEmpty {
                    Button {
                        input = ""
                    } label: {
                        Image(systemName: "xmark.rectangle.portrait")
                    }.padding(.leading)
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
                            .padding(.leading)
                    }
                    .padding(.trailing)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.gray, lineWidth: 1)
            )

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
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(
            for: UIApplication.willEnterForegroundNotification
        )) { _ in
            updatePasteboard()
        }
        #elseif canImport(AppKit)
        .onReceive(NotificationCenter.default.publisher(
            for: NSApplication.willBecomeActiveNotification
        )) { _ in
            updatePasteboard()
        }
        #endif
    }

    private func updatePasteboard() {
        #if canImport(UIKit)
        if let pasteBoardString = UIPasteboard.general.string {
            self.pasteBoardString = pasteBoardString
        }
        #elseif canImport(AppKit)
        if let pasteBoardString = NSPasteboard.general.string(forType: .string) {
            self.pasteBoardString = pasteBoardString
        }
        #endif
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
