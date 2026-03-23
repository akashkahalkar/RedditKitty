import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.pageLimitKey) private var pageLimit = AppSettings.defaultPageLimit
    @AppStorage(AppSettings.tintColorKey) private var tintColorHex = AppSettings.defaultTint.toHex
    @AppStorage(AppSettings.autoPlayVideoKey) private var autoPlayvideos = AppSettings.defaultAutoPlayVideo

    @AppStorage(AppSettings.ImageEnhancerSettings.brightnessKey) private var brightnessValue = AppSettings.ImageEnhancerSettings.brightnessDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.contrastKey) private var contrastValue = AppSettings.ImageEnhancerSettings.contrastDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.saturationKey) private var saturationValue = AppSettings.ImageEnhancerSettings.saturationDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.noiseLevelKey) private var noiseLevelValue = AppSettings.ImageEnhancerSettings.noiseLevelDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.noiseSharpnessKey) private var noiseSharpnessValue = AppSettings.ImageEnhancerSettings.noiseSharpnessDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.unsharpRadiusKey) private var unsharpRadiusValue = AppSettings.ImageEnhancerSettings.unsharpRadiusDefault
    @AppStorage(AppSettings.ImageEnhancerSettings.unsharpIntensityKey) private var unsharpIntensityValue = AppSettings.ImageEnhancerSettings.unsharpIntensityDefault

    @State private var isEnhancerSectionExpanded: Bool = false

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

                Section(isExpanded: $isEnhancerSectionExpanded) {
                    Stepper(value: $brightnessValue, in: AppSettings.ImageEnhancerSettings.brightnessRange, step: 0.01) {
                        Text("Brightness: \(brightnessValue, specifier: "%.2f")")
                    }
                    Stepper(value: $contrastValue, in: AppSettings.ImageEnhancerSettings.contrastRange, step: 0.01) {
                        Text("Contrast: \(contrastValue, specifier: "%.2f")")
                    }
                    Stepper(value: $saturationValue, in: AppSettings.ImageEnhancerSettings.saturationRange, step: 0.01) {
                        Text("Saturation: \(saturationValue, specifier: "%.2f")")
                    }
                    Stepper(value: $noiseLevelValue, in: AppSettings.ImageEnhancerSettings.noiseLevelRange, step: 0.01) {
                        Text("Noise Level: \(noiseLevelValue, specifier: "%.2f")")
                    }
                    Stepper(value: $noiseSharpnessValue, in: AppSettings.ImageEnhancerSettings.noiseSharpnessRange, step: 0.05) {
                        Text("Noise Sharpness: \(noiseSharpnessValue, specifier: "%.2f")")
                    }
                    Stepper(value: $unsharpRadiusValue, in: AppSettings.ImageEnhancerSettings.unsharpRadiusRange, step: 0.1) {
                        Text("Unsharp Radius: \(unsharpRadiusValue, specifier: "%.2f")")
                    }
                    Stepper(value: $unsharpIntensityValue, in: AppSettings.ImageEnhancerSettings.unsharpIntensityRange, step: 0.05) {
                        Text("Unsharp Intensity: \(unsharpIntensityValue, specifier: "%.2f")")
                    }

                    Button("Reset to Defaults", role: .destructive) {
                        resetEnhancerSettings()
                    }

                } header: {
                    HStack {
                        Text("Enhancer Section")
                        Spacer()
                        Button(action: {
                            withAnimation {
                                isEnhancerSectionExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isEnhancerSectionExpanded ? "chevron.up" : "chevron.down")
                        }
                        .frame(width: 20, height: 20)

                    }
                }


            }
            .navigationTitle("Settings")
        }
    }

    private func resetEnhancerSettings() {
        brightnessValue = AppSettings.ImageEnhancerSettings.brightnessDefault
        contrastValue = AppSettings.ImageEnhancerSettings.contrastDefault
        saturationValue = AppSettings.ImageEnhancerSettings.saturationDefault
        noiseLevelValue = AppSettings.ImageEnhancerSettings.noiseLevelDefault
        noiseSharpnessValue = AppSettings.ImageEnhancerSettings.noiseSharpnessDefault
        unsharpRadiusValue = AppSettings.ImageEnhancerSettings.unsharpRadiusDefault
        unsharpIntensityValue = AppSettings.ImageEnhancerSettings.unsharpIntensityDefault
    }
}

#Preview {
    SettingsView()
}
