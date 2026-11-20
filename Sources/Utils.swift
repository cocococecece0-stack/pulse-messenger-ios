
import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >> 8) & 0xFF) / 255
        let b = CGFloat(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

extension UIView {
    func pinToSuperview(insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: superview!.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func rounded(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}

extension Date {
    var timeString: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    var dayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d MMM"
        return f.string(from: self)
    }

    var relativeString: String {
        let interval = Date().timeIntervalSince(self)
        if interval < 60 { return "сейчас" }
        if interval < 3600 { return "\(Int(interval / 60)) мин" }
        if interval < 86400 { return timeString }
        if interval < 7 * 86400 { return dayString }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "d.MM"
        return f.string(from: self)
    }
}

extension String {
    var initials: String {
        let parts = split(separator: " ").filter { !$0.isEmpty }
        let letters = parts.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }
        return letters.joined()
    }
}

extension UINavigationController {
    func applyPulseStyle() {
        let p = ThemeManager.shared.current.palette
        navigationBar.prefersLargeTitles = true
        navigationBar.isTranslucent = true
        navigationBar.tintColor = p.accent
        navigationBar.largeTitleTextAttributes = [.foregroundColor: p.text,
                                                   .font: UIFont.systemFont(ofSize: 32, weight: .bold)]
        navigationBar.titleTextAttributes = [.foregroundColor: p.text]
        view.backgroundColor = p.bg
    }
}
