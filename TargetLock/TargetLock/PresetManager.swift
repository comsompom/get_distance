import Foundation

class PresetManager {
    func presets() -> [Preset] {
        return [
            Preset(title: "Adult Male (1.75m)", heightMeters: 1.75),
            Preset(title: "Adult Female (1.65m)", heightMeters: 1.65),
            Preset(title: "Child (1.20m)", heightMeters: 1.20),
            Preset(title: "Large Dog (0.70m)", heightMeters: 0.70),
            Preset(title: "Medium Dog (0.50m)", heightMeters: 0.50),
            Preset(title: "Small Dog (0.30m)", heightMeters: 0.30)
        ]
    }
}
