
import Foundation
import UIKit

extension Notification.Name {
    static let pulseThemeChanged = Notification.Name("pulseThemeChanged")
}

enum ThemeID: String, CaseIterable, Codable {
    case midnight, aurora, solar

    var title: String {
        switch self {
        case .midnight: return "Полуночный неон"
        case .aurora: return "Аврора"
        case .solar: return "Солар"
        }
    }

    var subtitle: String {
        switch self {
        case .midnight: return "Тёмный · фиолетово-розовый"
        case .aurora: return "Глубокий · бирюзовый"
        case .solar: return "Тёплый · оранжевый"
        }
    }
}

struct Palette {
    let bg: UIColor
    let bg2: UIColor
    let surface: UIColor
    let surface2: UIColor
    let accent: UIColor
    let accent2: UIColor
    let text: UIColor
    let text2: UIColor
    let border: UIColor
    let green: UIColor
    let red: UIColor
    let incoming: UIColor
    let outgoing1: UIColor
    let outgoing2: UIColor
}

struct Theme {
    let id: ThemeID
    let palette: Palette

    static func make(_ id: ThemeID) -> Theme {
        switch id {
        case .midnight:
            return Theme(id: .midnight, palette: Palette(
                bg: UIColor(red: 0.035, green: 0.035, blue: 0.075, alpha: 1),
                bg2: UIColor(red: 0.07, green: 0.04, blue: 0.13, alpha: 1),
                surface: UIColor(red: 0.085, green: 0.085, blue: 0.15, alpha: 1),
                surface2: UIColor(red: 0.13, green: 0.12, blue: 0.22, alpha: 1),
                accent: UIColor(red: 1.0, green: 0.22, blue: 0.52, alpha: 1),
                accent2: UIColor(red: 0.25, green: 0.85, blue: 1.0, alpha: 1),
                text: .white,
                text2: UIColor.white.withAlphaComponent(0.58),
                border: UIColor.white.withAlphaComponent(0.09),
                green: UIColor(red: 0.25, green: 0.95, blue: 0.62, alpha: 1),
                red: UIColor(red: 1.0, green: 0.36, blue: 0.38, alpha: 1),
                incoming: UIColor(red: 0.14, green: 0.13, blue: 0.23, alpha: 1),
                outgoing1: UIColor(red: 0.92, green: 0.16, blue: 0.48, alpha: 1),
                outgoing2: UIColor(red: 0.48, green: 0.20, blue: 0.85, alpha: 1)))
        case .aurora:
            return Theme(id: .aurora, palette: Palette(
                bg: UIColor(red: 0.02, green: 0.06, blue: 0.08, alpha: 1),
                bg2: UIColor(red: 0.03, green: 0.12, blue: 0.12, alpha: 1),
                surface: UIColor(red: 0.05, green: 0.11, blue: 0.13, alpha: 1),
                surface2: UIColor(red: 0.07, green: 0.18, blue: 0.19, alpha: 1),
                accent: UIColor(red: 0.20, green: 0.95, blue: 0.78, alpha: 1),
                accent2: UIColor(red: 0.30, green: 0.65, blue: 1.0, alpha: 1),
                text: .white,
                text2: UIColor.white.withAlphaComponent(0.58),
                border: UIColor.white.withAlphaComponent(0.09),
                green: UIColor(red: 0.40, green: 1.0, blue: 0.60, alpha: 1),
                red: UIColor(red: 1.0, green: 0.42, blue: 0.42, alpha: 1),
                incoming: UIColor(red: 0.06, green: 0.16, blue: 0.17, alpha: 1),
                outgoing1: UIColor(red: 0.10, green: 0.70, blue: 0.62, alpha: 1),
                outgoing2: UIColor(red: 0.12, green: 0.45, blue: 0.75, alpha: 1)))
        case .solar:
            return Theme(id: .solar, palette: Palette(
                bg: UIColor(red: 0.09, green: 0.05, blue: 0.03, alpha: 1),
                bg2: UIColor(red: 0.16, green: 0.07, blue: 0.04, alpha: 1),
                surface: UIColor(red: 0.14, green: 0.08, blue: 0.05, alpha: 1),
                surface2: UIColor(red: 0.22, green: 0.12, blue: 0.07, alpha: 1),
                accent: UIColor(red: 1.0, green: 0.62, blue: 0.18, alpha: 1),
                accent2: UIColor(red: 1.0, green: 0.28, blue: 0.36, alpha: 1),
                text: .white,
                text2: UIColor.white.withAlphaComponent(0.62),
                border: UIColor.white.withAlphaComponent(0.10),
                green: UIColor(red: 0.55, green: 0.95, blue: 0.45, alpha: 1),
                red: UIColor(red: 1.0, green: 0.36, blue: 0.30, alpha: 1),
                incoming: UIColor(red: 0.20, green: 0.11, blue: 0.07, alpha: 1),
                outgoing1: UIColor(red: 0.98, green: 0.48, blue: 0.14, alpha: 1),
                outgoing2: UIColor(red: 0.90, green: 0.20, blue: 0.28, alpha: 1)))
        }
    }
}

final class ThemeManager {
    static let shared = ThemeManager()

    private(set) var currentID: ThemeID

    private init() {
        if let raw = UserDefaults.standard.string(forKey: "pulse.theme"),
           let saved = ThemeID(rawValue: raw) {
            currentID = saved
        } else {
            currentID = .midnight
        }
    }

    var current: Theme { Theme.make(currentID) }

    func set(_ id: ThemeID) {
        currentID = id
        UserDefaults.standard.set(id.rawValue, forKey: "pulse.theme")
        NotificationCenter.default.post(name: .pulseThemeChanged, object: nil)
    }
}
