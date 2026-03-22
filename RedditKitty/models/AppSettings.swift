import Foundation
import SwiftUI

enum AppSettings {
    static let pageLimitKey = "settings.page_limit"
    static let tintColorKey = "settings.tint_color"
    static let autoPlayVideoKey = "settings.auto_play"

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
}
