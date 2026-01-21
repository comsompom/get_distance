import Foundation

enum DisplayUnit: String {
    case meters
    case feet
    case both
}

extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("appSettingsDidChange")
}

enum AppTheme: String {
    case system
    case light
    case dark
}

class AppSettings {
    static let shared = AppSettings()

    private let displayUnitKey = "display_unit"
    private let showGridKey = "show_grid_overlay"
    private let themeKey = "app_theme"
    private let defaults = UserDefaults.standard

    var displayUnit: DisplayUnit {
        get {
            if let raw = defaults.string(forKey: displayUnitKey),
               let unit = DisplayUnit(rawValue: raw) {
                return unit
            }
            return .both
        }
        set {
            defaults.set(newValue.rawValue, forKey: displayUnitKey)
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }

    var showGridOverlay: Bool {
        get { defaults.bool(forKey: showGridKey) }
        set {
            defaults.set(newValue, forKey: showGridKey)
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }

    var theme: AppTheme {
        get {
            if let raw = defaults.string(forKey: themeKey),
               let theme = AppTheme(rawValue: raw) {
                return theme
            }
            return .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: themeKey)
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }
}
