
import UIKit

final class StatsViewController: UIViewController {
    private let scroll = UIScrollView()
    private let content = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Статистика"
        build()
        applyStyle()
        NotificationCenter.default.addObserver(self, selector: #selector(applyStyle), name: .pulseThemeChanged, object: nil)
    }

    private func build() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor)
        ])

        let state = Storage.shared.state
        let outgoing = state.messages.filter { $0.outgoing }.count
        let read = state.messages.filter { $0.outgoing && $0.read }.count
        let reactions = state.messages.reduce(0) { $0 + $1.reactions.count }
        let groups = state.chats.filter { $0.kind == .group }.count
        let channels = state.chats.filter { $0.kind == .channel }.count
        let archived = state.chats.filter { $0.archived }.count
        let pinned = state.chats.filter { $0.pinned }.count

        let headline = UILabel()
        headline.text = "Ваш ПУЛЬС за 30 дней"
        headline.font = .systemFont(ofSize: 28, weight: .bold)
        headline.textAlignment = .center
        headline.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(headline)

        let cards: [(String, String)] = [
            ("\(state.messages.count)", "сообщений"),
            ("\(outgoing)", "отправлено"),
            ("\(read)", "прочитано"),
            ("\(reactions)", "реакций"),
            ("\(state.chats.count)", "чатов"),
            ("\(groups)", "групп"),
            ("\(channels)", "каналов"),
            ("\(pinned)", "закреплено"),
            ("\(archived)", "в архиве")
        ]

        var previous: NSLayoutYAxisAnchor = headline.bottomAnchor
        for (index, item) in cards.enumerated() {
            let card = UIView()
            card.layer.cornerRadius = 18
            card.tag = 3
            card.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(card)

            let value = UILabel()
            value.text = item.0
            value.font = .systemFont(ofSize: 28, weight: .bold)
            value.textAlignment = .center
            value.tag = 4
            value.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(value)

            let caption = UILabel()
            caption.text = item.1
            caption.font = .systemFont(ofSize: 12, weight: .medium)
            caption.textAlignment = .center
            caption.tag = 5
            caption.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(caption)

            NSLayoutConstraint.activate([
                card.topAnchor.constraint(equalTo: previous, constant: index == 0 ? 24 : 12),
                card.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
                card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
                card.heightAnchor.constraint(equalToConstant: 78),
                value.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
                value.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                value.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                caption.topAnchor.constraint(equalTo: value.bottomAnchor, constant: 2),
                caption.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                caption.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                caption.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10)
            ])
            previous = card.bottomAnchor
        }

        let chart = UIImageView(image: chartImage())
        chart.contentMode = .scaleAspectFit
        chart.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(chart)
        NSLayoutConstraint.activate([
            chart.topAnchor.constraint(equalTo: previous, constant: 28),
            chart.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            chart.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            chart.heightAnchor.constraint(equalToConstant: 180),
            chart.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -40)
        ])
        headline.tag = 6
        chart.tag = 7
    }

    private func chartImage() -> UIImage {
        let size = CGSize(width: 600, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let p = ThemeManager.shared.current.palette
            var rng = SeededRandom(4242)
            let points = (0..<24).map { i -> CGPoint in
                CGPoint(x: CGFloat(i) * size.width / 23, y: size.height - 30 - CGFloat(rng.int(20...220)))
            }
            let line = UIBezierPath()
            line.move(to: points[0])
            for i in 1..<points.count {
                let current = points[i]
                let previous = points[i - 1]
                let mid = CGPoint(x: (current.x + previous.x) / 2, y: (current.y + previous.y) / 2)
                line.addQuadCurve(to: mid, controlPoint: previous)
            }
            line.lineWidth = 4
            line.lineCapStyle = .round
            p.accent.setStroke()
            line.stroke()

            p.accent2.setFill()
            for point in points {
                UIBezierPath(ovalIn: CGRect(x: point.x - 3, y: point.y - 3, width: 6, height: 6)).fill()
            }
            p.text2.setFill()
            let font = UIFont.systemFont(ofSize: 13, weight: .medium)
            ("Пн" as NSString).draw(at: CGPoint(x: 8, y: size.height - 22), withAttributes: [.font: font, .foregroundColor: p.text2])
            ("Вс" as NSString).draw(at: CGPoint(x: size.width - 38, y: size.height - 22), withAttributes: [.font: font, .foregroundColor: p.text2])
        }
    }

    @objc private func applyStyle() {
        let p = ThemeManager.shared.current.palette
        view.backgroundColor = p.bg
        content.backgroundColor = .clear
        if let headline = content.viewWithTag(6) as? UILabel { headline.textColor = p.text }
        if let chart = content.viewWithTag(7) as? UIImageView { chart.image = chartImage() }
        for view in content.subviews where view.tag == 3 {
            view.backgroundColor = p.surface
            for sub in view.subviews {
                guard let label = sub as? UILabel else { continue }
                label.textColor = label.tag == 4 ? p.text : p.text2
            }
        }
    }
}
