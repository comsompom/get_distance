import Foundation

enum DisplayUnit: String {
    case meters
    case feet
    case both
}

class AppSettings {
    static let shared = AppSettings()

    private let displayUnitKey = "display_unit"
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
        }
    }
}
