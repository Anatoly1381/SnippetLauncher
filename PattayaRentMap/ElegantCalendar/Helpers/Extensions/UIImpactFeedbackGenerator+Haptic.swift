// Kevin Li - 8:58 PM - 7/9/20

#if canImport(UIKit)
import UIKit

extension UIImpactFeedbackGenerator {
    static func trigger(_ style: Style = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
#endif
