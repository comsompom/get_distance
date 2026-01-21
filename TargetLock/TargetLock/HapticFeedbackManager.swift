import UIKit

class HapticFeedbackManager {
    private let generator = UIImpactFeedbackGenerator(style: .light)

    func prepare() {
        generator.prepare()
    }

    func impactLight() {
        generator.prepare()
        generator.impactOccurred()
    }
}
