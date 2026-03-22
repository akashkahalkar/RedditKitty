import SwiftUI
import SwiftData

private enum PostFilter: String, CaseIterable, Identifiable {
    case user = "user"
    case subreddit = "subreddit"

    var id: String { rawValue }
}

struct SavedProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CachedListing.fetchedAt, order: .reverse) private var profiles: [CachedListing]
    @State private var path = NavigationPath()
    @State private var postFilter: PostFilter = .user

    private var filteredProfiles: [CachedListing] {
        switch postFilter {
            case .user:
                return profiles.filter { $0.sourceKind == PostFilter.user.rawValue }
            case .subreddit:
                return profiles.filter { $0.sourceKind == PostFilter.subreddit.rawValue }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if profiles.isEmpty {
                    ContentUnavailableView("No Saved Profiles", systemImage: "person.crop.circle.badge.exclamationmark")
                } else {
                    Picker("Post filter", selection: $postFilter) {
                        ForEach(PostFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    List {
                        ForEach(filteredProfiles) { profile in
                            NavigationLink(value: profile.sourceKey) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.sourceName)
                                        .font(.headline)
                                    Text("\(profile.sourceKind.capitalized)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete(perform: deleteProfiles)
                    }
                }
            }
            .navigationTitle("Saved Profiles")
            .navigationDestination(for: String.self) { sourceKey in
                if let profile = profiles.first(where: { $0.sourceKey == sourceKey }) {
                    ProfileGridView(sourceKey: profile.sourceKey, title: profile.sourceName)
                }
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        let sourceKeys = offsets.map { profiles[$0].sourceKey }

        for sourceKey in sourceKeys {
            deletePosts(for: sourceKey)
        }

        for index in offsets {
            modelContext.delete(profiles[index])
        }

        try? modelContext.save()
    }

    private func deletePosts(for sourceKey: String) {
        let descriptor = FetchDescriptor<CachedPost>(
            predicate: #Predicate { $0.sourceKey == sourceKey }
        )

        guard let posts = try? modelContext.fetch(descriptor) else {
            return
        }

        for post in posts {
            modelContext.delete(post)
        }
    }
}

#Preview {
    SavedProfilesView()
}
