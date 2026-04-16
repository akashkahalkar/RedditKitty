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

    var body: some View {

        let pageBinding = Binding<Int>(
            get: { PostFilter.allCases.firstIndex(of: postFilter) ?? 0 },
            set: { postFilter = PostFilter.allCases[$0] }
        )

        let filterCases = Array(PostFilter.allCases.enumerated())

        NavigationStack(path: $path) {
            Group {
                Picker("Post filter", selection: $postFilter) {
                    ForEach(PostFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 8)
                .padding(.top, 8)

                TabView(selection: pageBinding) {
                    ForEach(filterCases, id: \.offset) { index, filter in
                        let profilesForFilter = filteredProfiles(for: filter)
                        if !profilesForFilter.isEmpty {
                            List {
                                ForEach(profilesForFilter) { profile in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profile.sourceName)
                                                .font(.headline)
                                            Text(profile.sourceKind.capitalized)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            deleteProfile(profile)
                                        } label: {
                                            Image(systemName: "trash")
                                                .padding()
                                        }.buttonStyle(.borderless)
                                    }
                                    .overlay {
                                        NavigationLink(value: profile.sourceKey) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                    }
                                }
                            }
                            .tag(index)
                            .listStyle(.plain)
                        } else {
                            EmptyState()
                        }

                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.horizontal)

            }
            .navigationTitle("Saved Profiles")
            .navigationDestination(for: String.self) { sourceKey in
                if let profile = profiles.first(where: { $0.sourceKey == sourceKey }) {
                    ProfileGridView(sourceKey: profile.sourceKey, title: profile.sourceName)
                }
            }
        }
    }

    private func filteredProfiles(for filter: PostFilter) -> [CachedListing] {
        profiles.filter { $0.sourceKind == filter.rawValue }
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

        let cacheURLs = Set(
            posts
                .flatMap { $0.imageURLs + $0.thumbUrls }
                .compactMap(URL.init(string:))
        )

        if !cacheURLs.isEmpty {
            Task {
                await ImageCacheRepository.shared.removeCaches(for: Array(cacheURLs))
            }
        }

        for post in posts {
            modelContext.delete(post)
        }
    }

    private func deleteProfile(_ profile: CachedListing) {
        let sourceKey = profile.sourceKey
        deletePosts(for: sourceKey)
        modelContext.delete(profile)
        try? modelContext.save()
    }
}

#Preview {
    SavedProfilesView()
}
