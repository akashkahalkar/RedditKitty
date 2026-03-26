import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            SavedProfilesView()
                .tabItem {
                    Label("Profiles", systemImage: "person.2")
                }
            FetchProfileView()
                .tabItem {
                    Label("Fetch", systemImage: "arrow.down.circle")
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
