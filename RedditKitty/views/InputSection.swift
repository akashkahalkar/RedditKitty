import SwiftUI
import UIKit

struct InputSection: View {
    @Binding var input: String
    @Binding var isUserMode: Bool
    @Binding var postType: PostType?
    @State private var pasteboardString: String?
    @State private var hasCheckedPasteboard = false

    var body: some View {
        let inputBinding = Binding(
            get: { input },
            set: { newValue in
                input = newValue
                if let detected = parseRedditURL(newValue) {
                    withAnimation {
                        switch detected {
                        case .user:
                            isUserMode = true
                        case .subreddit:
                            isUserMode = false
                        }
                        self.postType = detected
                    }
                }
            }
        )

        VStack(spacing: 12) {
            HStack {
                TextField(isUserMode ? "Reddit username" : "Subreddit name", text: inputBinding)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                
                if let string = pasteboardString, !string.isEmpty {
                    Button {
                        if let postType = parseRedditURL(string) {
                            input = postType.name
                            self.postType = postType
                            withAnimation {
                                switch postType {
                                case .user:
                                    isUserMode = true
                                case .subreddit:
                                    isUserMode = false
                                }
                            }
                        } else {
                            input = string
                        }
                    } label: {
                        Image(systemName: "doc.on.doc.fill").padding()
                    }
                }
            }

            Toggle(isOn: $isUserMode) {
                Text(isUserMode ? "User" : "Subreddit")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .onAppear {
            refreshPasteboardString()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            refreshPasteboardString()
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

    private func refreshPasteboardString() {
        if let raw = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines) {
            pasteboardString = raw
        }
    }
}
