
import UIKit

final class Feedback {
    static let shared = Feedback()

    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notify = UINotificationFeedbackGenerator()

    private var enabled: Bool { Storage.shared.state.hapticsOn }

    func tap() {
        guard enabled else { return }
        light.impactOccurred()
    }

    func click() {
        guard enabled else { return }
        medium.impactOccurred()
    }

    func thud() {
        guard enabled else { return }
        heavy.impactOccurred()
    }

    func success() {
        guard enabled else { return }
        notify.notificationOccurred(.success)
    }

    func warning() {
        guard enabled else { return }
        notify.notificationOccurred(.warning)
    }
}
