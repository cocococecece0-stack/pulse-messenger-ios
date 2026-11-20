
import UIKit

final class MessageCell: UITableViewCell {
    static let reuse = "MessageCell"

    private let bubble = UIView()
    private let stack = UIStackView()
    private var gradient = CAGradientLayer()
    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!
    private var bubbleWidth: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubble.layer.cornerRadius = 18
        bubble.layer.masksToBounds = true
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        gradient.cornerRadius = 18
        bubble.layer.insertSublayer(gradient, at: 0)

        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(stack)

        leadingC = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12)
        trailingC = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        bubbleWidth = bubble.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width * 0.76)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            bubbleWidth,
            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bubble.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(_ message: Message) {
        let p = ThemeManager.shared.current.palette
        leadingC.isActive = !message.outgoing
        trailingC.isActive = message.outgoing

        bubble.backgroundColor = message.outgoing ? .clear : p.incoming
        gradient.isHidden = !message.outgoing
        gradient.colors = [p.outgoing1.cgColor, p.outgoing2.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        for view in stack.arrangedSubviews {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        if let replyID = message.replyToID,
           let original = Storage.shared.state.messages.first(where: { $0.id == replyID }) {
            let reply = UILabel()
            reply.text = "↳ \(original.text)"
            reply.font = .systemFont(ofSize: 12, weight: .medium)
            reply.textColor = p.text2
            reply.numberOfLines = 1
            stack.addArrangedSubview(reply)
        }

        switch message.kind {
        case .image:
            let image = UIImageView(image: AvatarFactory.gradientImage(seed: message.mediaSeed,
                                                                      size: CGSize(width: 320, height: 180)))
            image.contentMode = .scaleAspectFill
            image.layer.cornerRadius = 12
            image.layer.masksToBounds = true
            image.heightAnchor.constraint(equalToConstant: 160).isActive = true
            stack.addArrangedSubview(image)
            addText(message.text, color: .white, size: 14, bold: false)
        case .voice:
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.heightAnchor.constraint(equalToConstant: 40).isActive = true

            let play = UIButton(type: .system)
            play.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            play.tintColor = .white
            play.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(play)

            let wave = UIImageView(image: AvatarFactory.waveform(seed: message.mediaSeed, width: 170))
            wave.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(wave)

            let duration = UILabel()
            duration.text = "0:\(String(format: "%02d", Int(message.duration ?? 12)))"
            duration.font = .systemFont(ofSize: 11, weight: .bold)
            duration.textColor = .white
            duration.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(duration)

            NSLayoutConstraint.activate([
                play.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                play.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                play.widthAnchor.constraint(equalToConstant: 32),
                play.heightAnchor.constraint(equalToConstant: 32),
                wave.leadingAnchor.constraint(equalTo: play.trailingAnchor, constant: 4),
                wave.centerYAnchor.constraint(equalTo: container.centerYAnchor),
                wave.widthAnchor.constraint(equalToConstant: 150),
                wave.heightAnchor.constraint(equalToConstant: 28),
                duration.leadingAnchor.constraint(equalTo: wave.trailingAnchor, constant: 4),
                duration.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                duration.centerYAnchor.constraint(equalTo: container.centerYAnchor)
            ])
            stack.addArrangedSubview(container)
        case .file:
            let icon = UIImageView(image: UIImage(systemName: "doc.fill"))
            icon.tintColor = .white
            icon.contentMode = .scaleAspectFit
            icon.heightAnchor.constraint(equalToConstant: 26).isActive = true
            stack.addArrangedSubview(icon)
            addText(message.fileName ?? "Файл", color: .white, size: 14, bold: true)
            addText(message.fileSize ?? "", color: UIColor.white.withAlphaComponent(0.7), size: 11, bold: false)
        case .location:
            let map = UIImageView(image: AvatarFactory.mapImage(seed: message.mediaSeed,
                                                                size: CGSize(width: 240, height: 120)))
            map.contentMode = .scaleAspectFill
            map.layer.cornerRadius = 12
            map.layer.masksToBounds = true
            map.heightAnchor.constraint(equalToConstant: 120).isActive = true
            stack.addArrangedSubview(map)
            addText(message.text, color: .white, size: 13, bold: false)
        case .link:
            addText("🔗 " + (message.linkTitle ?? "Ссылка"), color: .white, size: 14, bold: true)
            let url = UILabel()
            url.text = message.linkURL
            url.font = .systemFont(ofSize: 11)
            url.textColor = UIColor.white.withAlphaComponent(0.75)
            url.numberOfLines = 1
            stack.addArrangedSubview(url)
        case .sticker:
            let sticker = UILabel()
            sticker.text = message.text
            sticker.font = .systemFont(ofSize: 46, weight: .bold)
            sticker.textAlignment = .center
            stack.addArrangedSubview(sticker)
        case .system:
            addText(message.text, color: p.text2, size: 12, bold: false)
        case .text:
            addText(message.text, color: .white, size: 15, bold: false)
        }

        if !message.reactionSummary.isEmpty {
            let reaction = UILabel()
            reaction.text = message.reactionSummary
            reaction.font = .systemFont(ofSize: 12, weight: .bold)
            reaction.textColor = p.accent2
            stack.addArrangedSubview(reaction)
        }

        let meta = UILabel()
        let check = message.outgoing ? (message.read ? " ✓✓" : " ✓") : ""
        meta.text = message.timestamp.timeString + check + (message.edited ? " изм." : "")
        meta.font = .systemFont(ofSize: 10, weight: .medium)
        meta.textColor = message.outgoing ? UIColor.white.withAlphaComponent(0.75) : p.text2
        meta.textAlignment = .right
        stack.addArrangedSubview(meta)
    }

    private func addText(_ text: String, color: UIColor, size: CGFloat, bold: Bool) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: bold ? .semibold : .regular)
        label.textColor = color
        label.numberOfLines = 0
        stack.addArrangedSubview(label)
    }
}
