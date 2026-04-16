//
//  EmptyState.swift
//  RedditKitty
//
//  Created by Akash K on 15/04/26.
//

import SwiftUI

struct EmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.largeTitle)
            Text("No Profiles")
                .font(.title2)
            Text("Your list is currently empty.")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyState()
}
