import Foundation
import SwiftUI

enum AppSettings {
    static let pageLimitKey = "settings.page_limit"
    static let tintColorKey = "settings.tint_color"
    static let autoPlayVideoKey = "settings.auto_play"
    static let defaultAutoPlayVideo = true

    static let defaultPageLimit = 25
    static let minimumPageLimit = 10
    static let maximumPageLimit = 100

    static var pageLimit: Int {
        let saved = UserDefaults.standard.integer(forKey: pageLimitKey)
        let value = saved == 0 ? defaultPageLimit : saved
        return min(max(value, minimumPageLimit), maximumPageLimit)
    }

    static var defaultTint: Color {
        if let colorHex = UserDefaults.standard.string(forKey: tintColorKey) {
            return Color.init(hex: colorHex)
        }
        return Color.orange
    }

    enum ImageEnhancerSettings {
        static let brightnessKey = "enhancer.brightness"
        static let contrastKey = "enhancer.contrast"
        static let saturationKey = "enhancer.saturation"
        static let noiseLevelKey = "enhancer.noise_level"
        static let noiseSharpnessKey = "enhancer.noise_sharpness"
        static let unsharpRadiusKey = "enhancer.unsharp_radius"
        static let unsharpIntensityKey = "enhancer.unsharp_intensity"

        static let brightnessRange: ClosedRange<Double> = -0.2...0.2
        static let contrastRange: ClosedRange<Double> = 0.8...1.4
        static let saturationRange: ClosedRange<Double> = 0.8...1.4
        static let noiseLevelRange: ClosedRange<Double> = 0...0.1
        static let noiseSharpnessRange: ClosedRange<Double> = 0...2
        static let unsharpRadiusRange: ClosedRange<Double> = 0...5
        static let unsharpIntensityRange: ClosedRange<Double> = 0...2

        static let brightnessDefault = 0.02
        static let contrastDefault = 1.02
        static let saturationDefault = 1.05
        static let noiseLevelDefault = 0.02
        static let noiseSharpnessDefault = 0.4
        static let unsharpRadiusDefault = 2.5
        static let unsharpIntensityDefault = 0.8
    }
}
