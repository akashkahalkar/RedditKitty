//
//  RedditKittyApp.swift
//  RedditKitty
//
//  Created by Akash on 18/03/26.
//

import SwiftUI
import SwiftData

@main
struct RedditKittyApp: App {
    @AppStorage(AppSettings.tintColorKey) private var tintColorRaw = AppSettings.defaultTint.toHex
    @Environment(\.scenePhase) var scenePhase
    @State private var blurRadius: CGFloat = 0

    // Initialize the container eagerly here in App.init().
    //
    // The .modelContainer(for:) scene modifier initializes lazily — it only
    // sets up the SQLite store (WAL recovery, schema validation, coordinator
    // setup) the FIRST TIME any view accesses modelContext. That first access
    // happens during live UI interaction, blocking the main thread for 2-15s.
    //
    // Initializing here moves that cost to before the first frame is shown,
    // so the user sees at most a slightly slower launch screen, not a frozen UI.
    private let container: ModelContainer


    init() {
        do {
            container = try ModelContainer(for: CachedListing.self, CachedPost.self)
        } catch {
            fatalError("SwiftData container failed to initialize: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Color(hex: tintColorRaw))
                .blur(radius: blurRadius, opaque: true)
                .onChange(of: scenePhase) { _, newValue in
                    blurRadius = (newValue == .active) ? 0 : 20
                }
            
        }

        .modelContainer(container)
    }
}
