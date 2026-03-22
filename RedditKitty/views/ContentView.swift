import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            FetchProfileView()
                .tabItem {
                    Label("Fetch", systemImage: "arrow.down.circle")
                }

            SavedProfilesView()
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    ContentView()
}
