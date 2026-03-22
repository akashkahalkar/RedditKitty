import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.pageLimitKey) private var pageLimit = AppSettings.defaultPageLimit
    @AppStorage(AppSettings.tintColorKey) private var tintColorHex = AppSettings.defaultTint.toHex
    @AppStorage(AppSettings.autoPlayVideoKey) private var autoPlayvideos = false

    private var selectedTintOption: Binding<Color> {
        Binding(
            get: { Color(hex: tintColorHex) },
            set: { tintColorHex = $0.toHex }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Feed") {
                    Stepper(value: $pageLimit, in: AppSettings.minimumPageLimit...AppSettings.maximumPageLimit, step: 10) {
                        Text("Page Limit: \(pageLimit)")
                    }
                }

                Section("Appearance") {
                    ColorPicker("Theme Color", selection: selectedTintOption)
                    Toggle(isOn: $autoPlayvideos) {
                        Text("Auto play videos")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
